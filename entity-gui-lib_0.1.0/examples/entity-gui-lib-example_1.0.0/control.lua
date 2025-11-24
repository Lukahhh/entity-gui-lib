-- Example mod demonstrating entity-gui-lib features
-- This showcases: tabs, refresh, confirmation dialogs, priority, preview_size, and more

-- Define the remote interface with callback functions
remote.add_interface("entity_gui_lib_example", {
    -- Inserter GUI builder - demonstrates basic usage + confirmation dialog
    build_inserter_gui = function(container, entity, player)
        -- Info section
        container.add{
            type = "label",
            caption = "Custom Inserter GUI",
            style = "caption_label",
        }

        -- Show some entity info
        local info_flow = container.add{
            type = "flow",
            direction = "vertical",
        }
        info_flow.style.top_margin = 8

        info_flow.add{
            type = "label",
            caption = {"", "Position: ", entity.position.x, ", ", entity.position.y},
        }

        info_flow.add{
            type = "label",
            caption = {"", "Direction: ", tostring(entity.direction)},
        }

        -- Action buttons
        local button_flow = container.add{
            type = "flow",
            direction = "horizontal",
        }
        button_flow.style.top_margin = 8
        button_flow.style.horizontal_spacing = 8

        button_flow.add{
            type = "button",
            name = "example_rotate_button",
            caption = "Rotate",
        }

        button_flow.add{
            type = "button",
            name = "example_info_button",
            caption = "Print Info",
        }

        -- Destroy button (demonstrates confirmation dialog)
        button_flow.add{
            type = "button",
            name = "example_destroy_button",
            caption = "Destroy",
            style = "red_button",
            tooltip = "Destroy this inserter (with confirmation)",
        }
    end,

    close_inserter_gui = function(entity, player)
        player.print("Closed inserter GUI")
    end,

    -- Confirmation dialog callbacks
    confirm_destroy = function(player, data)
        local entity = data.entity
        if entity and entity.valid then
            player.print("Destroyed " .. entity.name)
            entity.destroy()
        end
        remote.call("entity_gui_lib", "close", player.index)
    end,

    cancel_destroy = function(player, data)
        player.print("Destruction cancelled")
    end,

    -- Assembler GUI builder - demonstrates refresh mechanism
    build_assembler_gui = function(container, entity, player)
        container.add{
            type = "label",
            caption = "Custom Assembler (with refresh)",
            style = "caption_label",
        }

        -- Recipe info
        local recipe = entity.get_recipe()
        if recipe then
            local recipe_flow = container.add{
                type = "flow",
                direction = "horizontal",
            }
            recipe_flow.style.vertical_align = "center"
            recipe_flow.style.top_margin = 8

            recipe_flow.add{
                type = "sprite",
                sprite = "recipe/" .. recipe.name,
            }
            recipe_flow.add{
                type = "label",
                caption = recipe.localised_name,
            }
        else
            container.add{
                type = "label",
                caption = "No recipe set",
                style = "bold_red_label",
            }
        end

        -- Crafting progress
        local progress_flow = container.add{
            type = "flow",
            direction = "vertical",
        }
        progress_flow.style.top_margin = 8

        progress_flow.add{
            type = "label",
            caption = "Crafting Progress:",
        }

        progress_flow.add{
            type = "progressbar",
            name = "example_progress_bar",
            value = entity.crafting_progress or 0,
        }

        -- Speed info
        container.add{
            type = "label",
            caption = {"", "Speed: ", string.format("%.1f%%", entity.crafting_speed * 100)},
        }

        -- Refresh button to demonstrate refresh feature
        local refresh_flow = container.add{
            type = "flow",
            direction = "horizontal",
        }
        refresh_flow.style.top_margin = 8

        refresh_flow.add{
            type = "button",
            name = "example_refresh_button",
            caption = "Refresh",
            tooltip = "Refresh GUI to see updated progress",
        }
    end,

    -- Assembler update callback - called every 10 ticks
    update_assembler_gui = function(content, entity, player)
        -- Find and update the progress bar
        for _, child in pairs(content.children) do
            if child.type == "flow" then
                for _, subchild in pairs(child.children) do
                    if subchild.name == "example_progress_bar" then
                        subchild.value = entity.crafting_progress or 0
                    end
                end
            end
        end
    end,

    -- Container/chest GUI builder - demonstrates tabbed interface
    build_container_gui = function(gui_container, entity, player)
        -- Create tabbed interface
        local _, tabs = remote.call("entity_gui_lib", "create_tabs", gui_container, {
            {name = "inventory", caption = "Inventory"},
            {name = "info", caption = "Info"},
        })

        -- Inventory tab
        local inventory = entity.get_inventory(defines.inventory.chest)
        if inventory then
            tabs.inventory.add{
                type = "label",
                caption = {"", "Slots: ", #inventory, " (", inventory.count_empty_stacks(), " empty)"},
            }

            -- Display inventory items
            local item_flow = tabs.inventory.add{
                type = "flow",
                direction = "horizontal",
            }
            item_flow.style.horizontal_spacing = 4
            item_flow.style.top_margin = 8

            local shown = 0
            for i = 1, #inventory do
                local stack = inventory[i]
                if stack and stack.valid_for_read then
                    item_flow.add{
                        type = "sprite-button",
                        sprite = "item/" .. stack.name,
                        number = stack.count,
                        tooltip = stack.prototype.localised_name,
                        style = "slot_button",
                    }
                    shown = shown + 1
                    if shown >= 10 then
                        break
                    end
                end
            end

            if shown == 0 then
                item_flow.add{
                    type = "label",
                    caption = "(empty)",
                }
            end
        end

        -- Info tab
        tabs.info.add{
            type = "label",
            caption = "Container Information",
            style = "caption_label",
        }

        local info_flow = tabs.info.add{
            type = "flow",
            direction = "vertical",
        }
        info_flow.style.top_margin = 8

        info_flow.add{
            type = "label",
            caption = {"", "Name: ", entity.name},
        }
        info_flow.add{
            type = "label",
            caption = {"", "Position: ", entity.position.x, ", ", entity.position.y},
        }
        info_flow.add{
            type = "label",
            caption = {"", "Health: ", entity.health or "N/A"},
        }
    end,

    -- Accumulator GUI builder - demonstrates larger preview size
    build_accumulator_gui = function(container, entity, player)
        container.add{
            type = "label",
            caption = "Custom Accumulator GUI (large preview)",
            style = "caption_label",
        }

        local info = container.add{
            type = "flow",
            direction = "vertical",
        }
        info.style.top_margin = 8

        -- Energy stored
        local energy = entity.energy or 0
        local max_energy = entity.electric_buffer_size or 1
        local percent = (energy / max_energy) * 100

        info.add{
            type = "label",
            caption = {"", "Charge: ", string.format("%.1f%%", percent)},
        }

        info.add{
            type = "progressbar",
            value = energy / max_energy,
        }

        info.add{
            type = "label",
            caption = {"", "Energy: ", string.format("%.1f MJ / %.1f MJ", energy / 1000000, max_energy / 1000000)},
        }
    end,

    -- Mining drill GUI builder - demonstrates another entity type
    build_drill_gui = function(container, entity, player)
        container.add{
            type = "label",
            caption = "Custom Mining Drill GUI",
            style = "caption_label",
        }

        local info = container.add{
            type = "flow",
            direction = "vertical",
        }
        info.style.top_margin = 8

        -- Mining progress
        info.add{
            type = "label",
            caption = "Mining Progress:",
        }

        info.add{
            type = "progressbar",
            name = "example_drill_progress",
            value = entity.mining_progress or 0,
        }

        -- Mining speed
        info.add{
            type = "label",
            caption = {"", "Speed: ", string.format("%.1f%%", (entity.prototype.mining_speed or 1) * 100)},
        }

        -- Resource info
        local resource = entity.mining_target
        if resource and resource.valid then
            info.add{
                type = "label",
                caption = {"", "Mining: ", resource.localised_name},
            }
            info.add{
                type = "label",
                caption = {"", "Remaining: ", resource.amount or "N/A"},
            }
        else
            info.add{
                type = "label",
                caption = "No resource",
                style = "bold_red_label",
            }
        end
    end,

    -- Mining drill update callback - called every 10 ticks
    update_drill_gui = function(content, entity, player)
        -- Find and update the progress bar
        for _, child in pairs(content.children) do
            if child.type == "flow" then
                for _, subchild in pairs(child.children) do
                    if subchild.name == "example_drill_progress" then
                        subchild.value = entity.mining_progress or 0
                    end
                end
            end
        end
    end,

    -- Lab GUI builder - demonstrates new GUI element helpers
    build_lab_gui = function(container, entity, player)
        container.add{
            type = "label",
            caption = "Custom Lab GUI (Helper Demos)",
            style = "caption_label",
        }

        local content = container.add{
            type = "flow",
            direction = "vertical",
        }
        content.style.top_margin = 8
        content.style.vertical_spacing = 12

        -- Slider example
        content.add{
            type = "label",
            caption = "Slider Helper:",
            style = "bold_label",
        }
        remote.call("entity_gui_lib", "create_slider", content, {
            label = "Research Speed",
            min = 0,
            max = 100,
            value = 50,
            step = 5,
            mod_name = "entity_gui_lib_example",
            on_change = "on_slider_change",
            data = {entity_id = entity.unit_number},
        })

        -- Number input example
        content.add{
            type = "label",
            caption = "Number Input Helper:",
            style = "bold_label",
        }
        remote.call("entity_gui_lib", "create_number_input", content, {
            label = "Module Count",
            value = 2,
            min = 0,
            max = 10,
            step = 1,
            mod_name = "entity_gui_lib_example",
            on_change = "on_number_change",
            data = {entity_id = entity.unit_number},
        })

        -- Dropdown example
        content.add{
            type = "label",
            caption = "Dropdown Helper:",
            style = "bold_label",
        }
        remote.call("entity_gui_lib", "create_dropdown", content, {
            label = "Priority",
            items = {"Low", "Normal", "High", "Critical"},
            values = {"low", "normal", "high", "critical"},
            selected_index = 2,
            mod_name = "entity_gui_lib_example",
            on_change = "on_dropdown_change",
            data = {entity_id = entity.unit_number},
        })

        -- Toggle group (checkboxes) example
        content.add{
            type = "label",
            caption = "Checkbox Group:",
            style = "bold_label",
        }
        remote.call("entity_gui_lib", "create_toggle_group", content, {
            label = "Features",
            options = {
                {caption = "Auto-pause", value = "pause", state = false, tooltip = "Pause when full"},
                {caption = "Notify", value = "notify", state = true, tooltip = "Notify on complete"},
                {caption = "Recycle", value = "recycle", state = false},
            },
            mod_name = "entity_gui_lib_example",
            on_change = "on_toggle_change",
            data = {entity_id = entity.unit_number},
        })

        -- Toggle group (radio buttons with mutual exclusion) example
        content.add{
            type = "label",
            caption = "Radio Button Group:",
            style = "bold_label",
        }
        remote.call("entity_gui_lib", "create_toggle_group", content, {
            label = "Mode",
            mutual_exclusion = true,
            options = {
                {caption = "Automatic", value = "auto", state = true},
                {caption = "Manual", value = "manual"},
                {caption = "Disabled", value = "disabled"},
            },
            mod_name = "entity_gui_lib_example",
            on_change = "on_mode_change",
            data = {entity_id = entity.unit_number},
        })
    end,

    -- Callbacks for the new helpers
    on_slider_change = function(player, value, data)
        player.print("Slider changed to: " .. value)
    end,

    on_number_change = function(player, value, data)
        player.print("Number input changed to: " .. value)
    end,

    on_dropdown_change = function(player, index, value, data)
        player.print("Dropdown changed to: " .. value .. " (index " .. index .. ")")
    end,

    on_toggle_change = function(player, state, value, data)
        player.print("Toggle '" .. value .. "' is now: " .. (state and "ON" or "OFF"))
    end,

    on_mode_change = function(player, state, value, data)
        if state then
            player.print("Mode changed to: " .. value)
        end
    end,
})

-- Register GUIs with the library
local function register_guis()
    -- Enable debug mode to see registrations in log
    remote.call("entity_gui_lib", "set_debug_mode", true)

    -- Example 1: Custom inserter GUI
    remote.call("entity_gui_lib", "register", {
        mod_name = "entity_gui_lib_example",
        entity_type = "inserter",
        title = "Custom Inserter",
        on_build = "build_inserter_gui",
        on_close = "close_inserter_gui",
    })

    -- Example 2: Custom assembling machine GUI with auto-refresh
    remote.call("entity_gui_lib", "register", {
        mod_name = "entity_gui_lib_example",
        entity_type = "assembling-machine",
        title = "Custom Assembler",
        on_build = "build_assembler_gui",
        on_update = "update_assembler_gui",
        update_interval = 10,  -- Update every 10 ticks (~6 times/sec)
    })

    -- Example 3: Custom container/chest GUI with tabs
    remote.call("entity_gui_lib", "register", {
        mod_name = "entity_gui_lib_example",
        entity_type = "container",
        title = "Custom Chest",
        on_build = "build_container_gui",
    })

    -- Example 4: Custom accumulator GUI with larger preview
    remote.call("entity_gui_lib", "register", {
        mod_name = "entity_gui_lib_example",
        entity_type = "accumulator",
        title = "Custom Accumulator",
        on_build = "build_accumulator_gui",
        preview_size = 200,  -- Larger preview (default is 148)
    })

    -- Example 5: Custom mining drill GUI with auto-refresh
    remote.call("entity_gui_lib", "register", {
        mod_name = "entity_gui_lib_example",
        entity_type = "mining-drill",
        title = "Custom Mining Drill",
        on_build = "build_drill_gui",
        on_update = "update_drill_gui",
        update_interval = 10,
    })

    -- Example 6: Custom lab GUI demonstrating new element helpers
    remote.call("entity_gui_lib", "register", {
        mod_name = "entity_gui_lib_example",
        entity_type = "lab",
        title = "Custom Lab (Helpers Demo)",
        on_build = "build_lab_gui",
    })

    -- Example 7: Priority system demonstration
    -- If another mod registered "inserter" with lower priority, ours would win
    -- You can check existing registrations:
    local existing = remote.call("entity_gui_lib", "get_registrations", "inserter")
    for _, reg in ipairs(existing) do
        log("[entity_gui_lib_example] Found registration: " .. reg.mod_name .. " (priority: " .. reg.priority .. ")")
    end
end

-- Register on init and load
script.on_init(register_guis)
script.on_load(register_guis)

-- Handle button clicks
script.on_event(defines.events.on_gui_click, function(event)
    local element = event.element
    if not element or not element.valid then
        return
    end

    local player = game.get_player(event.player_index)
    if not player then
        return
    end

    -- Rotate inserter
    if element.name == "example_rotate_button" then
        local entity = remote.call("entity_gui_lib", "get_entity", event.player_index)
        if entity and entity.valid then
            entity.rotate()
            player.print("Rotated inserter!")
        end

    -- Print entity info
    elseif element.name == "example_info_button" then
        local entity = remote.call("entity_gui_lib", "get_entity", event.player_index)
        if entity and entity.valid then
            player.print("Entity: " .. entity.name .. " at " .. serpent.line(entity.position))
        end

    -- Destroy with confirmation
    elseif element.name == "example_destroy_button" then
        local entity = remote.call("entity_gui_lib", "get_entity", event.player_index)
        if entity and entity.valid then
            remote.call("entity_gui_lib", "show_confirmation", event.player_index, {
                mod_name = "entity_gui_lib_example",
                title = "Confirm Destruction",
                message = {"", "Are you sure you want to destroy this ", entity.localised_name, "?"},
                confirm_caption = "Destroy",
                cancel_caption = "Cancel",
                on_confirm = "confirm_destroy",
                on_cancel = "cancel_destroy",
                data = {entity = entity},
            })
        end

    -- Refresh assembler GUI
    elseif element.name == "example_refresh_button" then
        local success = remote.call("entity_gui_lib", "refresh", event.player_index)
        if success then
            player.print("GUI refreshed!")
        end
    end
end)
