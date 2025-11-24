-- Example mod demonstrating entity-gui-lib

-- Define the remote interface with callback functions
remote.add_interface("entity_gui_lib_example", {
    -- Inserter GUI builder
    build_inserter_gui = function(container, entity, player)
        -- Info section
        container.add{
            type = "label",
            caption = "This is a custom inserter GUI!",
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

        -- Add a button
        local button_flow = container.add{
            type = "flow",
            direction = "horizontal",
        }
        button_flow.style.top_margin = 8

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
    end,

    close_inserter_gui = function(entity, player)
        player.print("Closed inserter GUI")
    end,

    -- Assembler GUI builder
    build_assembler_gui = function(container, entity, player)
        container.add{
            type = "label",
            caption = "Custom assembling machine interface",
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
    end,

    -- Container/chest GUI builder
    build_container_gui = function(gui_container, entity, player)
        gui_container.add{
            type = "label",
            caption = "Custom chest interface",
            style = "caption_label",
        }

        -- Show inventory slot count
        local inventory = entity.get_inventory(defines.inventory.chest)
        if inventory then
            gui_container.add{
                type = "label",
                caption = {"", "Slots: ", #inventory, " (", inventory.count_empty_stacks(), " empty)"},
            }

            -- Add the actual inventory widget
            gui_container.add{
                type = "label",
                caption = "Inventory:",
                style = "caption_label",
            }.style.top_margin = 8

            -- Note: For actual inventory interaction, you'd need more complex handling
            -- This is just a display example
            local item_flow = gui_container.add{
                type = "flow",
                direction = "horizontal",
            }
            item_flow.style.horizontal_spacing = 4

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
    end,
})

-- Register GUIs with the library
local function register_guis()
    -- Example 1: Custom inserter GUI (replaces ALL inserters)
    remote.call("entity_gui_lib", "register", {
        mod_name = "entity_gui_lib_example",
        entity_type = "inserter",
        title = "Custom Inserter GUI",
        on_build = "build_inserter_gui",
        on_close = "close_inserter_gui",
    })

    -- Example 2: Custom assembling machine GUI
    remote.call("entity_gui_lib", "register", {
        mod_name = "entity_gui_lib_example",
        entity_type = "assembling-machine",
        title = "Custom Assembler",
        on_build = "build_assembler_gui",
    })

    -- Example 3: Custom container/chest GUI
    remote.call("entity_gui_lib", "register", {
        mod_name = "entity_gui_lib_example",
        entity_type = "container",
        title = "Custom Chest",
        on_build = "build_container_gui",
    })
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

    if element.name == "example_rotate_button" then
        local entity = remote.call("entity_gui_lib", "get_entity", event.player_index)
        if entity and entity.valid then
            entity.rotate()
            player.print("Rotated inserter!")
        end

    elseif element.name == "example_info_button" then
        local entity = remote.call("entity_gui_lib", "get_entity", event.player_index)
        if entity and entity.valid then
            player.print("Entity: " .. entity.name .. " at " .. serpent.line(entity.position))
        end
    end
end)
