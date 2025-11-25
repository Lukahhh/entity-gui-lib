# Entity GUI Library

A Factorio 2.0 library mod that provides barebones entity GUIs for mod authors to extend. Automatically replaces vanilla entity GUIs with customizable frames that include entity preview, status display, and a content area for your custom controls.

## Features

### Core
- Proper vanilla-styled frame with titlebar and close button
- Entity preview and status display (35+ status types supported)
- Automatically intercepts and replaces vanilla entity GUIs
- Clean API via remote interface
- Supports both entity name and entity type registration

### Keyboard Support
- E key closes GUI (matches vanilla behavior)
- Escape key closes GUI

### Multi-Mod Support
- Priority system for handling conflicts between mods
- Check existing registrations before registering
- Per-mod unregister support

### Helpers
- Tabbed interface helper
- Confirmation dialog helper
- Slider with label and value display
- Number input with +/- buttons
- Dropdown with callback handling
- Toggle/checkbox group with mutual exclusion option
- Inventory display with clickable slots
- Recipe selector with search and filtering
- Item selector with search and filtering
- Signal selector for circuit network signals
- Element button (choose-elem-button wrapper)
- Color picker with RGB sliders
- GUI refresh without closing (for live data)
- Debug mode for logging registrations and events

## Installation

Add `entity-gui-lib` as a dependency in your mod's `info.json`:

```json
{
  "dependencies": ["entity-gui-lib"]
}
```

## Usage

### Basic Registration

Register your custom GUI by providing your mod name and callback function names:

```lua
-- Define your remote interface with callback functions
remote.add_interface("my_mod", {
    build_my_gui = function(container, entity, player)
        container.add{
            type = "label",
            caption = "Hello from my custom GUI!",
        }

        container.add{
            type = "button",
            name = "my_button",
            caption = "Click me",
        }
    end,

    close_my_gui = function(entity, player)
        -- Optional: called when GUI closes
        player.print("GUI closed")
    end,
})

-- Register with the library
local function register_guis()
    remote.call("entity_gui_lib", "register", {
        mod_name = "my_mod",                    -- Your mod's remote interface name
        entity_name = "my-custom-entity",       -- Specific entity name
        -- OR entity_type = "inserter",         -- All entities of this type
        title = "My Custom GUI",                -- Optional: custom title
        on_build = "build_my_gui",              -- Callback function name
        on_close = "close_my_gui",              -- Optional: close callback name
    })
end

script.on_init(register_guis)
script.on_load(register_guis)
```

### Registration Config

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `mod_name` | string | Yes | Your mod's remote interface name |
| `entity_name` | string | One of these | Specific entity name to replace |
| `entity_type` | string | required | Entity type to replace (e.g., "inserter", "container") |
| `title` | LocalisedString | No | Custom title (defaults to entity name) |
| `on_build` | string | Yes | Name of callback function in your remote interface |
| `on_close` | string | No | Name of close callback function |
| `on_update` | string | No | Name of update callback for auto-refresh |
| `update_interval` | number | No | Ticks between updates (default: 10, ~6 times/sec) |
| `priority` | number | No | Priority for conflict resolution (default: 0, higher wins) |
| `preview_size` | number | No | Size of entity preview in pixels (default: 148) |
| `show_player_inventory` | boolean | No | Show player's inventory panel alongside entity GUI (default: false) |

### Callback Signatures

**on_build**: `function(container, entity, player)`
- `container`: LuaGuiElement - Flow element to add your GUI children to
- `entity`: LuaEntity - The entity the GUI was opened for
- `player`: LuaPlayer - The player who opened the GUI

**on_close**: `function(entity, player)`
- `entity`: LuaEntity - The entity (may be invalid if destroyed)
- `player`: LuaPlayer - The player who closed the GUI

**on_update**: `function(content, entity, player)`
- `content`: LuaGuiElement - The content container (same as on_build)
- `entity`: LuaEntity - The entity the GUI is showing
- `player`: LuaPlayer - The player viewing the GUI

### Auto-Refresh Example

For live-updating GUIs (progress bars, energy levels, etc.), use `on_update`:

```lua
remote.add_interface("my_mod", {
    build_drill_gui = function(container, entity, player)
        container.add{
            type = "progressbar",
            name = "my_progress",
            value = entity.mining_progress or 0,
        }
    end,

    update_drill_gui = function(content, entity, player)
        -- Find and update the progress bar
        for _, child in pairs(content.children) do
            if child.name == "my_progress" then
                child.value = entity.mining_progress or 0
            end
        end
    end,
})

remote.call("entity_gui_lib", "register", {
    mod_name = "my_mod",
    entity_type = "mining-drill",
    on_build = "build_drill_gui",
    on_update = "update_drill_gui",
    update_interval = 10,  -- Update every 10 ticks
})
```

### Multiple Registrations & Priority

When multiple mods register for the same entity, the highest priority wins:

```lua
-- Mod A registers with default priority (0)
remote.call("entity_gui_lib", "register", {
    mod_name = "mod_a",
    entity_type = "inserter",
    on_build = "build_inserter_gui",
})

-- Mod B registers with higher priority - this one will be used
remote.call("entity_gui_lib", "register", {
    mod_name = "mod_b",
    entity_type = "inserter",
    on_build = "build_inserter_gui",
    priority = 100,
})
```

Check existing registrations before registering:

```lua
local existing = remote.call("entity_gui_lib", "get_registrations", "inserter")
for _, reg in ipairs(existing) do
    log("Mod " .. reg.mod_name .. " registered with priority " .. reg.priority)
end
```

## Remote Interface Functions

### Core Functions

```lua
-- Register an entity GUI
remote.call("entity_gui_lib", "register", config)

-- Unregister an entity GUI (all mods)
remote.call("entity_gui_lib", "unregister", "entity-name-or-type")

-- Unregister only your mod's registration
remote.call("entity_gui_lib", "unregister", "entity-name-or-type", "your_mod_name")

-- Get all registrations for an entity (for conflict checking)
local registrations = remote.call("entity_gui_lib", "get_registrations", "entity-name-or-type")

-- Get the content container for a player's open GUI
local container = remote.call("entity_gui_lib", "get_content", player_index)

-- Get the entity for a player's open GUI
local entity = remote.call("entity_gui_lib", "get_entity", player_index)

-- Refresh/rebuild GUI content without closing (useful for live data)
local success = remote.call("entity_gui_lib", "refresh", player_index)

-- Close a player's GUI programmatically
remote.call("entity_gui_lib", "close", player_index)

-- Refresh an inventory display's slots without rebuilding the GUI
-- inv_table: the table element returned by create_inventory_display
-- inventory: the LuaInventory to refresh from
local success = remote.call("entity_gui_lib", "refresh_inventory_display", inv_table, inventory)
```

### Listener Functions (Cross-Mod Integration)

Listen for GUI open/close events on entities registered by other mods:

```lua
-- Register as a listener for entity GUIs
remote.call("entity_gui_lib", "add_listener", {
    mod_name = "my_observer_mod",
    entity_type = "inserter",       -- or entity_name = "specific-entity"
    on_open = "my_open_callback",   -- optional
    on_close = "my_close_callback", -- optional
})

-- Remove a listener
remote.call("entity_gui_lib", "remove_listener", "inserter", "my_observer_mod")

-- Get all listeners for an entity
local listeners = remote.call("entity_gui_lib", "get_listeners", "inserter")
```

**Listener Callback Signatures:**

```lua
-- on_open: Called after the registering mod's on_build callback
function(content, entity, player, registering_mod_name)

-- on_close: Called after the registering mod's on_close callback
function(entity, player, registering_mod_name)
```

**Use Cases:**
- Cross-mod integration (react when another mod's GUI opens)
- Overlay/addon mods that enhance other mods' GUIs
- Logging or analytics
- Adding indicators or tooltips to third-party entity GUIs

### Helper Functions

#### Tabbed Interface

```lua
-- In your on_build callback:
local tabbed_pane, tab_contents = remote.call("entity_gui_lib", "create_tabs", container, {
    {name = "info", caption = "Info"},
    {name = "settings", caption = "Settings"},
})

-- Add content to each tab
tab_contents.info.add{type = "label", caption = "Info tab content"}
tab_contents.settings.add{type = "label", caption = "Settings tab content"}
```

#### Confirmation Dialog

```lua
-- Add callbacks to your remote interface
remote.add_interface("my_mod", {
    show_delete = function(player_index, entity_data)
        remote.call("entity_gui_lib", "show_confirmation", player_index, {
            mod_name = "my_mod",
            title = "Confirm Delete",
            message = "Are you sure you want to delete this?",
            confirm_caption = "Delete",      -- optional, defaults to "Confirm"
            cancel_caption = "Keep",         -- optional, defaults to "Cancel"
            on_confirm = "do_delete",
            on_cancel = "cancel_delete",     -- optional
            data = entity_data,              -- passed to callbacks
        })
    end,

    do_delete = function(player, data)
        player.print("Deleted!")
    end,

    cancel_delete = function(player, data)
        player.print("Cancelled")
    end,
})
```

#### Slider

Create a labeled slider with automatic value display:

```lua
remote.add_interface("my_mod", {
    build_gui = function(container, entity, player)
        remote.call("entity_gui_lib", "create_slider", container, {
            label = "Speed",
            min = 0,
            max = 100,
            value = 50,
            step = 5,
            mod_name = "my_mod",
            on_change = "on_speed_change",
            data = {entity_id = entity.unit_number},
        })
    end,

    on_speed_change = function(player, value, data)
        player.print("Speed set to: " .. value)
    end,
})
```

#### Number Input

Create a text field with increment/decrement buttons:

```lua
remote.call("entity_gui_lib", "create_number_input", container, {
    label = "Count",
    value = 10,
    min = 1,
    max = 100,
    step = 1,
    mod_name = "my_mod",
    on_change = "on_count_change",
})
```

#### Dropdown

Create a dropdown with callback handling:

```lua
remote.call("entity_gui_lib", "create_dropdown", container, {
    label = "Mode",
    items = {"Option A", "Option B", "Option C"},
    values = {"a", "b", "c"},  -- optional, maps to callback
    selected_index = 1,
    mod_name = "my_mod",
    on_change = "on_mode_change",
})

-- Callback signature: function(player, selected_index, selected_value, data)
```

#### Toggle/Checkbox Group

Create grouped checkboxes or radio buttons:

```lua
-- Checkboxes (multiple selection)
remote.call("entity_gui_lib", "create_toggle_group", container, {
    label = "Features",
    options = {
        {caption = "Auto-sort", value = "sort", state = true},
        {caption = "Filter", value = "filter", state = false},
        {caption = "Limit", value = "limit", state = false, tooltip = "Limit stack size"},
    },
    horizontal = false,         -- optional, vertical layout (default: false)
    mod_name = "my_mod",
    on_change = "on_feature_toggle",
})

-- Radio buttons (single selection with mutual exclusion)
remote.call("entity_gui_lib", "create_toggle_group", container, {
    label = "Priority",
    mutual_exclusion = true,    -- makes it behave like radio buttons
    use_radiobuttons = true,    -- optional, use radiobutton style instead of checkbox
    options = {
        {caption = "Low", value = "low"},
        {caption = "Normal", value = "normal", state = true},
        {caption = "High", value = "high"},
    },
    mod_name = "my_mod",
    on_change = "on_priority_change",
})

-- Callback signature: function(player, state, value, data)
```

#### Inventory Display

Display an entity's inventory with clickable slot buttons:

```lua
remote.add_interface("my_mod", {
    build_gui = function(container, entity, player)
        local inventory = entity.get_inventory(defines.inventory.chest)
        if inventory then
            remote.call("entity_gui_lib", "create_inventory_display", container, {
                inventory = inventory,
                columns = 10,           -- optional, default 10
                show_empty = true,      -- optional, show empty slots
                mod_name = "my_mod",
                on_click = "on_slot_click",
                data = {entity_id = entity.unit_number},
            })
        end
    end,

    on_slot_click = function(player, slot_index, item_stack, data)
        player.print("Clicked slot " .. slot_index .. " containing " .. (item_stack and item_stack.name or "nothing"))
    end,
})
```

**Interactive Inventory** - Enable item transfers between player and entity:

```lua
remote.call("entity_gui_lib", "create_inventory_display", container, {
    inventory = inventory,
    interactive = true,         -- enable item transfers
    read_only = false,          -- optional, prevent transfers even when interactive
    item_filter = {             -- optional, restrict allowed items
        ["iron-plate"] = true,
        ["copper-plate"] = true,
    },
    mod_name = "my_mod",
    on_transfer = "on_item_transfer",
    data = {entity_id = entity.unit_number},
})

-- on_transfer callback signature: function(player, slot_index, transfer_type, data)
-- transfer_type: "insert", "take", "swap", or "quick_transfer"
```

**Interactive behavior:**
- Left-click with items in cursor: Insert full stack
- Right-click with items in cursor: Insert half stack
- Left-click with empty cursor: Take all items from slot
- Right-click with empty cursor: Take half of items from slot
- Shift-click: Quick transfer items to/from player inventory

#### Recipe Selector

Create a searchable recipe picker with filtering:

```lua
remote.call("entity_gui_lib", "create_recipe_selector", container, {
    player = player,
    force = player.force,       -- optional, defaults to player's force
    filter = {{filter = "category", category = "crafting"}},  -- optional prototype filter
    show_search = true,         -- optional, default true
    columns = 10,               -- optional, default 10
    mod_name = "my_mod",
    on_select = "on_recipe_selected",
})

-- Callback signature: function(player, recipe_name, data)
```

#### Item Selector

Create a searchable item picker with filtering:

```lua
remote.call("entity_gui_lib", "create_item_selector", container, {
    filter = {{filter = "type", type = "tool"}},  -- optional prototype filter
    show_search = true,         -- optional, default true
    columns = 10,               -- optional, default 10
    mod_name = "my_mod",
    on_select = "on_item_selected",
})

-- Callback signature: function(player, item_name, data)
```

#### Element Button

Create a simple choose-elem-button for items, recipes, signals, fluids, or entities:

```lua
-- Item picker button
remote.call("entity_gui_lib", "create_elem_button", container, {
    elem_type = "item",         -- "item", "recipe", "signal", "fluid", or "entity"
    value = "iron-plate",       -- optional initial value
    mod_name = "my_mod",
    on_change = "on_elem_changed",
})

-- Callback signature: function(player, elem_value, data)
```

#### Signal Selector

Create a circuit network signal selector:

```lua
remote.call("entity_gui_lib", "create_signal_selector", container, {
    value = {type = "item", name = "iron-plate"},  -- optional initial SignalID
    mod_name = "my_mod",
    on_change = "on_signal_changed",
})

-- Callback signature: function(player, signal_id, data)
-- signal_id is a SignalID: {type = "item"|"fluid"|"virtual", name = string}
```

#### Color Picker

Create an RGB color picker with sliders:

```lua
remote.call("entity_gui_lib", "create_color_picker", container, {
    color = {r = 1, g = 0.5, b = 0, a = 1},  -- optional initial color (0-1 range)
    show_alpha = false,         -- optional, show alpha slider
    mod_name = "my_mod",
    on_change = "on_color_changed",
})

-- Callback signature: function(player, color, data)
-- color is {r = 0-1, g = 0-1, b = 0-1, a = 0-1}
```

### Debug Mode

Enable debug logging to see registrations and GUI events in the Factorio log:

```lua
-- Enable debug mode
remote.call("entity_gui_lib", "set_debug_mode", true)

-- Check if debug mode is enabled
local enabled = remote.call("entity_gui_lib", "is_debug_mode")
```

Log output appears in `factorio-current.log`:
- Windows: `%APPDATA%\Factorio\factorio-current.log`
- Linux: `~/.factorio/factorio-current.log`
- macOS: `~/Library/Application Support/factorio/factorio-current.log`

Example log output:
```
[entity-gui-lib] Registered: inserter by my_mod (priority: 0)
[entity-gui-lib] Opened GUI for inserter (player: PlayerName, mod: my_mod)
```

## Handling GUI Events

Handle button clicks and other GUI events in your mod:

```lua
script.on_event(defines.events.on_gui_click, function(event)
    local element = event.element
    if not element or not element.valid then return end

    if element.name == "my_button" then
        local entity = remote.call("entity_gui_lib", "get_entity", event.player_index)
        if entity and entity.valid then
            -- Do something with the entity
        end
    end
end)
```

## Example

See the `examples/entity-gui-lib-example` folder for a complete working example that demonstrates:
- Custom inserter GUI with rotation button
- Custom assembling machine GUI with recipe display
- Custom container GUI with inventory display

## License

MIT
