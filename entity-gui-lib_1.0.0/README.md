# Entity GUI Library

A Factorio 2.0 library mod for creating custom entity GUIs that replace vanilla ones.

## Features

- Intercepts vanilla entity GUIs and replaces them with customizable versions
- Provides a barebones frame with:
  - Draggable titlebar
  - Close button
  - Entity preview
  - Entity status display
  - Content area for custom elements
- Vanilla-like styling
- Simple remote interface API

## Usage

Add `entity-gui-lib` as a dependency in your mod's `info.json`:

```json
{
    "dependencies": [
        "entity-gui-lib >= 1.0.0"
    ]
}
```

### Registering an Entity

In your `control.lua`, register entities to use custom GUIs:

```lua
-- Register during on_init and on_load
local function register_guis()
    remote.call("entity_gui_lib", "register", {
        entity_name = "my-custom-inserter",  -- specific entity name
        -- OR entity_type = "inserter",      -- all entities of this type
        title = "Custom Inserter",           -- optional title override

        on_build = function(container, entity, player)
            -- Add your custom GUI elements to container
            container.add{
                type = "label",
                caption = "Custom content here!"
            }

            container.add{
                type = "button",
                name = "my_button",
                caption = "Do Something"
            }
        end,

        on_close = function(entity, player)
            -- Optional: cleanup when GUI closes
        end,
    })
end

script.on_init(register_guis)
script.on_load(register_guis)
```

### API Reference

#### `remote.call("entity_gui_lib", "register", config)`

Register an entity for custom GUI replacement.

**Config options:**
- `entity_name` (string): Specific entity name to match
- `entity_type` (string): Entity type to match (used if entity_name not specified)
- `title` (LocalisedString): Optional title override
- `on_build` (function): Called when GUI is created. Receives `(container, entity, player)`
- `on_close` (function): Optional callback when GUI closes. Receives `(entity, player)`

#### `remote.call("entity_gui_lib", "unregister", entity_name_or_type)`

Remove a registration.

#### `remote.call("entity_gui_lib", "get_content", player_index)`

Get the content container element for a player's open GUI.

#### `remote.call("entity_gui_lib", "get_entity", player_index)`

Get the entity for a player's open GUI.

#### `remote.call("entity_gui_lib", "close", player_index)`

Programmatically close the custom GUI for a player.

### Handling GUI Events

Handle clicks on your custom elements in your own event handlers:

```lua
script.on_event(defines.events.on_gui_click, function(event)
    if event.element.name == "my_button" then
        local entity = remote.call("entity_gui_lib", "get_entity", event.player_index)
        if entity then
            -- Do something with the entity
        end
    end
end)
```

## Example

See the mod page for a complete example implementation.

## License

MIT
