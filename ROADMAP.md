# Entity GUI Library - Roadmap

Future improvements and features under consideration. Feedback welcome!

---

## GUI Element Helpers

### Sliders & Inputs
- **Slider helper** - Create labeled sliders with min/max/step and value display
- **Number input** - Text field with validation, increment/decrement buttons
- **Dropdown helper** - Pre-configured dropdowns with callback handling
- **Toggle/checkbox group** - Grouped toggles with mutual exclusion option

### Common Patterns
- **Inventory display** - Helper for showing entity inventories with slot buttons
- **Recipe selector** - Searchable recipe picker with preview
- **Item selector** - Item picker with filtering
- **Signal selector** - For circuit network signals
- **Color picker** - HSV or RGB color selection

---

## Advanced Features

### Circuit Network Integration
- Display current circuit network connections
- Show signal values
- Wire connection visualization

### Entity Relationships
- Show connected entities (belts, pipes, wires)
- Mini-map with entity position
- Range/area visualization

### State Management
- Persist GUI state between sessions (collapsed sections, selected tabs)
- Undo/redo for complex operations
- Form validation with error display

---

## Quality of Life

### Styling & Theming
- Pre-built color schemes
- Consistent spacing/margin presets
- Icon/sprite helpers

### Event Simplification
- Simplified click handler registration
- Debounced inputs for sliders/text
- Keyboard shortcut registration

### Tooltips
- Rich tooltip builder (multi-line, icons, colors)
- Dynamic tooltips that update

---

## Performance & Optimization

- Lazy loading for complex GUIs
- Virtualized lists for large datasets
- Batched updates for multiple elements

---

## Documentation & Examples

- Video tutorials
- More example mods (complex real-world cases)
- Interactive API playground
- Migration guide from manual GUI code

---

## Community Requests

### GUI Event Listener System
Allow mods to observe GUI open/close events for entities they didn't register, enabling cross-mod integration and overlay features.

**Proposed API:**
```lua
-- Register as a listener for specific entity type
remote.call("entity_gui_lib", "add_listener", {
    mod_name = "my_observer_mod",
    entity_type = "inserter",      -- or entity_name for specific entities
    -- entity_name = "my-entity",  -- alternative: specific entity
    -- entity_filter = "*",        -- alternative: listen to ALL entity GUIs
    on_open = "my_open_callback",
    on_close = "my_close_callback",
})

-- Callback signatures:
-- on_open: function(content, entity, player, registering_mod_name)
-- on_close: function(entity, player, registering_mod_name)

-- Remove listener
remote.call("entity_gui_lib", "remove_listener", "inserter", "my_observer_mod")

-- Get all listeners for an entity
local listeners = remote.call("entity_gui_lib", "get_listeners", "inserter")
```

**Use Cases:**
- Cross-mod integration (Mod B reacts when Mod A's GUI opens)
- Overlay/addon mods that enhance other mods' GUIs
- Logging/analytics mods
- Global GUI event tracking
- Adding tooltips or indicators to third-party entity GUIs

**Implementation Notes:**
- Listeners called AFTER the registering mod's on_build/on_close
- Multiple listeners per entity supported (called in registration order)
- Listener callbacks receive the registering mod's name for context
- Priority system possible for listener ordering

---

## Contributing

If you'd like to contribute to any of these features, please open an issue on GitHub to discuss implementation approach before starting work.

## Feedback

Which features would be most useful for your mod? Let us know in the discussion thread!
