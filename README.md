# Entity GUI Library

A Factorio library mod that provides barebones entity GUIs for mod authors to extend. Automatically replaces vanilla entity GUIs with customizable frames that include entity preview, status display, and a content area for your custom controls.

## Features

- Proper vanilla-styled frame with titlebar and close button
- Entity preview and status display
- Automatically intercepts and replaces vanilla entity GUIs
- Clean API via remote interface
- Supports both entity name and entity type registration

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
| `priority` | number | No | Priority for conflict resolution (default: 0, higher wins) |

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

### Callback Signatures

**on_build**: `function(container, entity, player)`
- `container`: LuaGuiElement - Flow element to add your GUI children to
- `entity`: LuaEntity - The entity the GUI was opened for
- `player`: LuaPlayer - The player who opened the GUI

**on_close**: `function(entity, player)`
- `entity`: LuaEntity - The entity (may be invalid if destroyed)
- `player`: LuaPlayer - The player who closed the GUI

### Remote Interface Functions

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
```

### Handling GUI Events

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
