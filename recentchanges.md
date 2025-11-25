-----
  Interaction behavior:

  - Left-click empty slot with cursor item → Insert all items
  - Left-click filled slot with same item → Stack items (respects stack size)
  - Left-click filled slot with different item → Swap items
  - Left-click filled slot with empty cursor → Take all items
  - Right-click filled slot with empty cursor → Take half

  New remote function:

  - refresh_inventory_display(inv_table, inventory) - Updates slot visuals from inventory

  Example usage:

  -- In your on_build callback:
  local scroll, inv_table = remote.call("entity_gui_lib", "create_inventory_display", content, {
      inventory = entity.get_inventory(defines.inventory.chest),
      columns = 10,
      interactive = true,  -- Enable item transfers
      item_filter = {["rocket-part"] = true},  -- Optional: only allow rocket parts
      mod_name = "my-mod",
      on_transfer = "on_inventory_changed",  -- Optional callback
  })

  -- Store inv_table reference if you need to refresh later

-----

  New Registration Option

  Add show_player_inventory = true when registering your entity:

  remote.call("entity_gui_lib", "register", {
      mod_name = "my-rocket-silo-mod",
      entity_name = "my-rocket-silo",
      title = "Custom Rocket Silo",
      on_build = "build_silo_gui",
      show_player_inventory = true,  -- Shows player inventory panel on the right
  })

  What it does

  - Adds a scrollable player inventory panel to the right of your custom GUI
  - Fully interactive - click to pick up items, click again to drop them
  - Right-click takes half a stack
  - Auto-refreshes every tick (configurable via update_interval)
  - Works with your entity's interactive inventory slots for easy item transfer

-----

Interactive Inventory Support

  The create_inventory_display helper now supports interactive item transfers between the player's cursor and inventory slots.

  New parameters:
  - interactive (boolean) - Enable click-to-transfer items with player cursor
  - read_only (boolean) - Disable transfers even if interactive is true
  - item_filter (table) - Optional whitelist of allowed items, e.g. {["iron-plate"] = true}
  - on_transfer (string) - Remote callback name triggered after item transfers

  Interaction behaviors:
  - Left-click empty slot with cursor item → Insert all items
  - Left-click filled slot with same item → Stack items (respects stack size)
  - Left-click filled slot with different item → Swap items
  - Left-click filled slot with empty cursor → Take all items
  - Right-click filled slot with empty cursor → Take half stack

  Player Inventory Panel

  New registration option show_player_inventory displays an interactive player inventory panel alongside custom
  entity GUIs - similar to vanilla entity GUI behavior.

  Usage:
  remote.call("entity_gui_lib", "register", {
      mod_name = "my-mod",
      entity_name = "my-entity",
      on_build = "build_gui",
      show_player_inventory = true,
  })

  Features:
  - Fully interactive - click to pick up/place items
  - Auto-refreshes based on update_interval
  - Works in both normal mode (character inventory) and editor/god mode (god inventory)
  - Shows "(Editor)" label suffix when using god mode inventory

  New Remote Functions

  - refresh_inventory_display(inv_table, inventory) - Manually refresh inventory slot visuals

  Bug Fixes

  - Fixed function ordering issue where get_helper_callbacks was called before being defined
  - Fixed GUI element hierarchy for refresh and get_content remote functions after adding main_flow wrapper

  Internal Changes

  - Moved debug_mode and get_helper_callbacks definitions earlier in file for use in build_entity_gui
  - Added storage.inventory_refs for tracking interactive inventory references
  - Added player_inv_source tracking to handle character vs god mode inventory refresh
  - Enhanced debug logging to show show_player_inventory and inventory status

-----

 Bug Fixes

  1. Tab Focus Issue

  - Added tab selection preservation during refresh
  - The on_tick handler now saves and restores selected_tab_index on any tabbed panes in the content area

  2. Shift-Click Quick Transfer

  - Added shift+click support to transfer items between inventories
  - Clicking player inventory slot → transfers to entity inventory
  - Clicking entity inventory slot → transfers to player inventory
  - Stacks with existing items first, then uses empty slots
  - Both inventory displays refresh immediately after transfer

  3. Smooth Interaction (Refresh Conflicts)

  - Added INTERACTION_COOLDOWN (30 ticks / ~0.5 seconds)
  - Tracks last_interaction_tick when transfers occur
  - Skips periodic refresh during cooldown to prevent visual glitches
  - Also added refresh_inventory_slots() helper for immediate visual updates

  Interaction Summary

  | Action                                    | Result                            |
  |-------------------------------------------|-----------------------------------|
  | Left-click slot with item on cursor       | Insert/swap items                 |
  | Left-click filled slot with empty cursor  | Take all items                    |
  | Right-click filled slot with empty cursor | Take half stack                   |
  | Shift + left-click filled slot            | Quick transfer to other inventory |


  -----

  Fixed Function Definition Order

  - Moved get_helper_callbacks() and debug_mode to the top of the file
  - These were being called in build_entity_gui before they were defined, causing errors

  Fixed Editor/God Mode Support

  - Player inventory panel now works without a character
  - Automatically detects and uses god_main inventory in editor/god mode
  - Shows "(Editor)" suffix in the inventory label when using god mode inventory

  Fixed Numeric Inventory ID Error

  - create_inventory_display uses numeric IDs while player inventories use string IDs like "player_1"
  - Added type() checks before calling string methods to prevent "attempt to index number" errors
  - Shift-click quick transfer now correctly identifies inventory types

  Fixed Tab Reset on Quick Transfer

  - Setting last_interaction_tick after quick transfers now prevents periodic refresh from interfering
  - Tab selection is preserved when shift-clicking items between inventories

  New Features

  Shift-Click Quick Transfer

  - Shift + left-click on a filled slot transfers items to the "other" inventory
  - From player inventory → transfers to entity inventory
  - From entity inventory → transfers to player inventory
  - Stacks with existing items of the same type first, then uses empty slots
  - Both inventory displays refresh immediately after transfer

  Interaction Cooldown System

  - Added INTERACTION_COOLDOWN constant (30 ticks / ~0.5 seconds)
  - Tracks last_interaction_tick when any inventory transfer occurs
  - Periodic on_tick refresh skips during cooldown to prevent:
    - Visual glitches during rapid clicking
    - Tab selection being reset
    - Interference with user interactions

  Tab Selection Preservation

  - on_tick handler now saves and restores selected_tab_index on tabbed panes
  - Prevents mod update callbacks from accidentally resetting tab selection

  Internal Improvements

  - Added refresh_inventory_slots(inv_id) helper function for immediate visual updates
  - Improved inventory type detection using type() checks
  - Better separation of quick transfer logic from regular cursor transfers

-----

Key Changes:

  1. Created update_slot_visual helper - Centralizes all slot visual updates with consistent behavior
  2. Fixed sprite clearing - Changed element.sprite = nil to element.sprite = "" (empty string). Factorio may not
  handle nil correctly for clearing sprites.
  3. Fixed tooltip clearing - Same fix: element.tooltip = "" instead of nil
  4. Improved refresh_inventory_slots:
    - For player inventory: Uses stored gui_data.player_inv_table reference directly (faster, more reliable)
    - For entity inventories: Properly navigates through frame → main_flow → inner_frame → content hierarchy
    - Recursive search now checks child.children exists before recursing
  5. Unified all visual updates to use the same helper:
    - Click handler
    - on_tick refresh
    - refresh_inventory_display remote function
    - refresh_inventory_slots internal function

-----
Fix Summary

Problem

Entity inventories created via create_inventory_display were not auto-refreshing during the on_tick cycle. Only player inventory panels were being refreshed. (identified during testing of space-elevator proof of concept mod)

  Solution

  1. Added auto-refresh for entity inventory displays (lines 978-986):
  -- Refresh entity inventory displays created via create_inventory_display
  local inv_refs = storage.inventory_refs or {}
  for inv_id, inv_data in pairs(inv_refs) do
      -- Skip player inventories (they're handled above)
      local is_player_inv = type(inv_id) == "string" and inv_id:find("^player_")
      if not is_player_inv and inv_data.inventory and inv_data.inventory.valid then
          refresh_inventory_slots(inv_id)
      end
  end

  2. Added cleanup on GUI close (lines 442-454):
  - Removes player inventory ref when their GUI closes
  - Cleans up invalid inventory refs (where underlying inventory no longer exists)

  Behavior

  Now during each on_tick cycle (respecting update_interval and interaction cooldown):
  1. Mod's on_update callback is called
  2. Tab selection is preserved
  3. Player inventory panel is refreshed
  4. All entity inventory displays are auto-refreshed

 The space elevator mod's inventory display should now update automatically when inserters add materials, without needing to close and reopen the GUI.

-----

The issue was that we were restoring the tab selection before the inventory refreshes, so the entity inventory refresh (which was added later) was happening after the tabwas already restored.

  I moved the tab restoration to after all refreshes:
  1. Save tab index
  2. Call mod's on_update callback
  3. Refresh player inventory panel
  4. Refresh entity inventory displays
  5. Now restore tab selection (after all operations that might affect it)

-----
Fix single left click inventory moves

Now the click handler:
  1. Saves the tab index at the start of any interactive inventory transfer
  2. Performs the transfer operation
  3. Updates visuals and sets interaction cooldown
  4. Calls any callbacks
  5. Restores the tab index if it changed

-----

Performance Optimizations Implemented

  | #   | Optimization                 | What Changed
                                                                  |
  |-----|------------------------------|----------------------------------------------------------------------------
  ----------------------------------------------------------------|
  | 1   | Cache UI refs                | open_guis now stores frame, content, inner_frame directly. on_tick uses
  cached refs instead of traversing frame.children[2].children[1]... |
  | 2   | Inventory hash check         | Added compute_inventory_hash() function. Player inventory only refreshes
  when hash changes                                                 |
  | 3   | Direct inventory table refs  | storage.inventory_tables stores table elements. refresh_inventory_slots()
  rewritten to use direct refs instead of recursive DOM traversal  |
  | 4   | Early exit in event handlers | Added name:sub(1, #GUI_PREFIX) ~= GUI_PREFIX prefix check at start of all
  handlers (click, value_changed, text_changed, etc.)              |
  | 5   | Color picker refs            | Sliders store direct references to swatch, all_sliders, and value_label.
  Eliminates DOM traversal on every slider change                   |
  | 6   | Static status table          | get_status_lookup() builds table once at module level, not per GUI open
                                                                  |
  | 7   | Search debounce              | Item/recipe searches queue to storage.pending_searches, processed after 6
  tick delay (~100ms)                                              |

  Key Changes Summary

  - on_tick: Removed 15+ lines of GUI hierarchy traversal, added hash-based skip logic, added debounced search
  processing
  - Event handlers: All 6 handlers now early-exit on non-library elements using fast prefix check
  - refresh_inventory_slots: Reduced from O(players × GUI depth × slots) to O(slots)
  - New storage fields: inventory_tables, pending_searches
