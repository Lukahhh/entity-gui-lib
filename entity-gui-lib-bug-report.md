# Bug Report: Inventory Display Not Updating When Items Change

## Summary

The `create_inventory_display` helper does not refresh when the underlying inventory contents change. Items inserted via inserters or player interaction don't appear in the GUI until it's closed and reopened.

## Environment

- entity-gui-lib version: 0.1.1
- Factorio version: 2.0 with Space Age DLC

## Steps to Reproduce

1. Register a custom GUI with `on_update` callback and `update_interval`
2. Use `create_inventory_display` to show an entity's inventory
3. Open the custom GUI
4. Insert items into the inventory (via inserter or by closing GUI and using vanilla interface)
5. Observe: The inventory display does not update to show the new items
6. Close and reopen the GUI
7. Observe: Items now appear

## Expected Behavior

The inventory display should update periodically (matching `update_interval`) to reflect current inventory contents.

## Actual Behavior

The inventory display remains static showing the contents from when the GUI was opened. Only closing and reopening the GUI refreshes the inventory view.

## Technical Details

Our mod uses:
```lua
remote.call("entity_gui_lib", "register", {
    mod_name = "space_elevator",
    entity_name = "space-elevator",
    on_build = "build_elevator_gui",
    on_update = "update_elevator_gui",
    update_interval = 20,
    show_player_inventory = true,
})
```

And creates inventory display with:
```lua
remote.call("entity_gui_lib", "create_inventory_display", tabs.materials, {
    inventory = inventory,  -- LuaInventory from chest.get_inventory()
    columns = 10,
    show_empty = true,
    interactive = true,
    mod_name = "space_elevator",
    on_click = "on_inventory_click",
    on_transfer = "on_inventory_transfer",
})
```

The `on_update` callback is called and can update other elements (like progress bars), but we have no way to refresh the inventory display contents.

## Possible Solutions

### Option A: Auto-refresh inventory displays

During the periodic `on_update` cycle, automatically refresh any inventory displays created with `create_inventory_display` by re-reading the inventory contents and updating the slot buttons.

### Option B: Provide a refresh helper

Add a helper function that mods can call to refresh inventory displays:
```lua
remote.call("entity_gui_lib", "refresh_inventory_display", container, inventory)
```

### Option C: Return a reference for manual updates

Have `create_inventory_display` return a reference that can be used to update it:
```lua
local inv_display = remote.call("entity_gui_lib", "create_inventory_display", ...)
-- Later in on_update:
inv_display.refresh()  -- or remote.call to refresh by reference
```

## Workaround

Currently users must close and reopen the GUI to see inventory changes, which is not ideal for monitoring material collection progress.

## Related

This may be related to the same underlying issue as the periodic refresh system - the inventory display is created once and never updated, while other GUI elements can be updated in the `on_update` callback.
