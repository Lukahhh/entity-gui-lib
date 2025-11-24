-- Entity GUI Library
-- Provides barebones entity GUIs for mod authors to extend

local registered_entities = {}
local open_guis = {}

-- GUI element names
local GUI_PREFIX = "entity_gui_lib_"
local FRAME_NAME = GUI_PREFIX .. "frame"
local CONTENT_NAME = GUI_PREFIX .. "content"

---@param player LuaPlayer
---@param entity LuaEntity
---@param registration table
local function build_entity_gui(player, entity, registration)
    -- Close any existing custom GUI for this player
    if open_guis[player.index] then
        local old_frame = player.gui.screen[FRAME_NAME]
        if old_frame and old_frame.valid then
            old_frame.destroy()
        end
        open_guis[player.index] = nil
    end

    -- Create main frame
    local frame = player.gui.screen.add{
        type = "frame",
        name = FRAME_NAME,
        direction = "vertical",
    }
    frame.auto_center = true

    -- Titlebar
    local titlebar = frame.add{
        type = "flow",
        direction = "horizontal",
    }
    titlebar.drag_target = frame
    titlebar.style.horizontal_spacing = 8
    titlebar.style.height = 28

    -- Title label
    local title_text = registration.title or entity.localised_name or entity.name
    local title = titlebar.add{
        type = "label",
        caption = title_text,
        style = "frame_title",
        ignored_by_interaction = true,
    }
    title.drag_target = frame

    -- Drag handle (filler)
    local filler = titlebar.add{
        type = "empty-widget",
        style = "draggable_space_header",
    }
    filler.style.height = 24
    filler.style.horizontally_stretchable = true
    filler.style.left_margin = 4
    filler.style.right_margin = 4
    filler.drag_target = frame

    -- Close button
    titlebar.add{
        type = "sprite-button",
        name = GUI_PREFIX .. "close_button",
        sprite = "utility/close",
        hovered_sprite = "utility/close_black",
        clicked_sprite = "utility/close_black",
        style = "frame_action_button",
        tooltip = {"gui.close-instruction"},
    }

    -- Content area with entity info and custom content
    local inner_frame = frame.add{
        type = "frame",
        style = "entity_frame",
        direction = "vertical",
    }

    -- Entity preview and status flow
    local preview_flow = inner_frame.add{
        type = "flow",
        direction = "horizontal",
    }
    preview_flow.style.vertical_align = "center"
    preview_flow.style.horizontal_spacing = 8

    -- Entity preview
    local preview = preview_flow.add{
        type = "entity-preview",
        name = GUI_PREFIX .. "preview",
        style = "wide_entity_button",
    }
    preview.entity = entity
    local preview_size = registration.preview_size or 148
    preview.style.height = preview_size
    preview.style.width = preview_size

    -- Status section
    local status_flow = preview_flow.add{
        type = "flow",
        direction = "vertical",
    }
    status_flow.style.vertical_spacing = 4

    -- Entity status lookup table (built dynamically to handle missing statuses)
    local status_info = {}
    local es = defines.entity_status

    -- Helper to safely add status
    local function add_status(key, sprite, caption)
        if key then status_info[key] = {sprite, caption} end
    end

    -- Working states
    add_status(es.working, "utility/status_working", {"entity-status.working"})
    add_status(es.normal, "utility/status_working", {"entity-status.normal"})

    -- Yellow/warning states
    add_status(es.low_power, "utility/status_yellow", {"entity-status.low-power"})
    add_status(es.waiting_for_source_items, "utility/status_yellow", {"entity-status.waiting-for-source-items"})
    add_status(es.waiting_for_space_in_destination, "utility/status_yellow", {"entity-status.waiting-for-space-in-destination"})
    add_status(es.charging, "utility/status_yellow", {"entity-status.charging"})
    add_status(es.waiting_for_target_to_be_built, "utility/status_yellow", {"entity-status.waiting-for-target-to-be-built"})
    add_status(es.waiting_for_train, "utility/status_yellow", {"entity-status.waiting-for-train"})
    add_status(es.preparing_rocket_for_launch, "utility/status_yellow", {"entity-status.preparing-rocket-for-launch"})
    add_status(es.waiting_to_launch_rocket, "utility/status_yellow", {"entity-status.waiting-to-launch-rocket"})
    add_status(es.waiting_for_more_parts, "utility/status_yellow", {"entity-status.waiting-for-more-parts"})
    add_status(es.item_ingredient_shortage, "utility/status_yellow", {"entity-status.item-ingredient-shortage"})
    add_status(es.fluid_ingredient_shortage, "utility/status_yellow", {"entity-status.fluid-ingredient-shortage"})
    add_status(es.full_output, "utility/status_yellow", {"entity-status.full-output"})
    add_status(es.not_connected_to_rail, "utility/status_yellow", {"entity-status.not-connected-to-rail"})
    add_status(es.cant_divide_segments, "utility/status_yellow", {"entity-status.cant-divide-segments"})
    add_status(es.idle, "utility/status_yellow", {"entity-status.idle"})

    -- Good/active states
    add_status(es.discharging, "utility/status_working", {"entity-status.discharging"})
    add_status(es.fully_charged, "utility/status_working", {"entity-status.fully-charged"})
    add_status(es.launching_rocket, "utility/status_working", {"entity-status.launching-rocket"})
    add_status(es.networks_connected, "utility/status_working", {"entity-status.networks-connected"})

    -- Not working states
    add_status(es.no_power, "utility/status_not_working", {"entity-status.no-power"})
    add_status(es.no_fuel, "utility/status_not_working", {"entity-status.no-fuel"})
    add_status(es.disabled_by_control_behavior, "utility/status_not_working", {"entity-status.disabled"})
    add_status(es.disabled_by_script, "utility/status_not_working", {"entity-status.disabled-by-script"})
    add_status(es.marked_for_deconstruction, "utility/status_not_working", {"entity-status.marked-for-deconstruction"})
    add_status(es.no_recipe, "utility/status_not_working", {"entity-status.no-recipe"})
    add_status(es.no_ingredients, "utility/status_not_working", {"entity-status.no-ingredients"})
    add_status(es.no_input_fluid, "utility/status_not_working", {"entity-status.no-input-fluid"})
    add_status(es.no_research_in_progress, "utility/status_not_working", {"entity-status.no-research-in-progress"})
    add_status(es.no_minable_resources, "utility/status_not_working", {"entity-status.no-minable-resources"})
    add_status(es.no_ammo, "utility/status_not_working", {"entity-status.no-ammo"})
    add_status(es.missing_required_fluid, "utility/status_not_working", {"entity-status.missing-required-fluid"})
    add_status(es.missing_science_packs, "utility/status_not_working", {"entity-status.missing-science-packs"})
    add_status(es.networks_disconnected, "utility/status_not_working", {"entity-status.networks-disconnected"})
    add_status(es.out_of_logistic_network, "utility/status_not_working", {"entity-status.out-of-logistic-network"})
    add_status(es.no_modules_to_transmit, "utility/status_not_working", {"entity-status.no-modules-to-transmit"})
    add_status(es.recharging_after_power_outage, "utility/status_not_working", {"entity-status.recharging-after-power-outage"})
    add_status(es.frozen, "utility/status_not_working", {"entity-status.frozen"})
    add_status(es.paused, "utility/status_not_working", {"entity-status.paused"})

    -- Get status display info
    local status = entity.status
    local status_sprite = "utility/status_working"
    local status_caption = {"entity-status.working"}

    if status and status_info[status] then
        status_sprite = status_info[status][1]
        status_caption = status_info[status][2]
    end

    local status_line = status_flow.add{
        type = "flow",
        direction = "horizontal",
    }
    status_line.style.vertical_align = "center"
    status_line.style.horizontal_spacing = 4

    status_line.add{
        type = "sprite",
        sprite = status_sprite,
    }
    status_line.add{
        type = "label",
        caption = status_caption,
    }

    -- Custom content container
    local content = inner_frame.add{
        type = "flow",
        name = CONTENT_NAME,
        direction = "vertical",
    }
    content.style.top_margin = 8

    -- Call mod's build callback via remote interface
    if registration.mod_name and registration.on_build then
        remote.call(registration.mod_name, registration.on_build, content, entity, player)
    end

    -- Track open GUI
    open_guis[player.index] = {
        entity = entity,
        registration = registration,
        last_update_tick = game.tick,
    }

    -- Focus the frame
    player.opened = frame
end

---@param key string
---@return table|nil
local function get_highest_priority_registration(key)
    local registrations = registered_entities[key]
    if not registrations or #registrations == 0 then
        return nil
    end

    local highest = registrations[1]
    for i = 2, #registrations do
        if registrations[i].priority > highest.priority then
            highest = registrations[i]
        end
    end
    return highest
end

---@param entity LuaEntity
---@return table|nil
local function get_registration(entity)
    -- Check for specific entity name first
    local by_name = get_highest_priority_registration(entity.name)
    if by_name then
        return by_name
    end

    -- Check for entity type
    local by_type = get_highest_priority_registration(entity.type)
    if by_type then
        return by_type
    end

    return nil
end

-- Event handlers
script.on_event(defines.events.on_gui_opened, function(event)
    if event.gui_type ~= defines.gui_type.entity then
        return
    end

    local entity = event.entity
    if not entity or not entity.valid then
        return
    end

    local registration = get_registration(entity)
    if not registration then
        return
    end

    local player = game.get_player(event.player_index)
    if not player then
        return
    end

    -- Close the vanilla GUI
    player.opened = nil

    -- Build custom GUI
    build_entity_gui(player, entity, registration)

    if debug_mode then
        log("[entity-gui-lib] Opened GUI for " .. entity.name .. " (player: " .. player.name .. ", mod: " .. registration.mod_name .. ")")
    end
end)

script.on_event(defines.events.on_gui_closed, function(event)
    -- Only handle custom GUI closures
    if event.gui_type ~= defines.gui_type.custom then
        return
    end

    local player = game.get_player(event.player_index)
    if not player then
        return
    end

    local element = event.element
    if not element or not element.valid then
        return
    end

    if element.name ~= FRAME_NAME then
        return
    end

    -- Call on_close callback via remote interface
    local gui_data = open_guis[player.index]
    if gui_data and gui_data.registration.mod_name and gui_data.registration.on_close then
        remote.call(gui_data.registration.mod_name, gui_data.registration.on_close, gui_data.entity, player)
    end

    -- Clean up
    element.destroy()
    open_guis[player.index] = nil
end)

-- Helper callback storage (defined early for use in event handlers)
local function get_helper_callbacks()
    if not storage.helper_callbacks then
        storage.helper_callbacks = {}
    end
    return storage.helper_callbacks
end

-- Counter for unique element IDs
local helper_id_counter = 0
local function get_next_helper_id()
    helper_id_counter = helper_id_counter + 1
    return helper_id_counter
end

script.on_event(defines.events.on_gui_click, function(event)
    local element = event.element
    if not element or not element.valid then
        return
    end

    local player = game.get_player(event.player_index)
    if not player then
        return
    end

    -- Close button
    if element.name == GUI_PREFIX .. "close_button" then
        local frame = player.gui.screen[FRAME_NAME]
        if frame and frame.valid then
            player.opened = nil
        end
        return
    end

    -- Confirmation dialog buttons
    if element.name == GUI_PREFIX .. "confirm_ok" or element.name == GUI_PREFIX .. "confirm_cancel" then
        local confirmation = storage.confirmations and storage.confirmations[event.player_index]
        if confirmation then
            local callback = element.name == GUI_PREFIX .. "confirm_ok"
                and confirmation.on_confirm
                or confirmation.on_cancel

            if callback and confirmation.mod_name then
                remote.call(confirmation.mod_name, callback, player, confirmation.data)
            end

            storage.confirmations[event.player_index] = nil
        end

        -- Close confirmation dialog
        local confirm_frame = player.gui.screen[GUI_PREFIX .. "confirmation"]
        if confirm_frame and confirm_frame.valid then
            confirm_frame.destroy()
        end
        return
    end

    -- Number input increment/decrement buttons
    if element.name:find("^" .. GUI_PREFIX .. "number_inc_") or element.name:find("^" .. GUI_PREFIX .. "number_dec_") then
        local is_increment = element.name:find("^" .. GUI_PREFIX .. "number_inc_")
        local input_name = element.name:gsub("number_inc_", "number_input_"):gsub("number_dec_", "number_input_")

        local callbacks = get_helper_callbacks()
        local callback_data = callbacks[input_name]
        if not callback_data then return end

        -- Find the text field
        local parent = element.parent
        if not parent then return end

        local text_field
        for _, child in pairs(parent.children) do
            if child.name == input_name then
                text_field = child
                break
            end
        end

        if not text_field then return end

        local current = tonumber(text_field.text) or callback_data.default or 0
        local step = callback_data.step or 1
        local new_value = is_increment and (current + step) or (current - step)

        -- Clamp value
        if callback_data.min and new_value < callback_data.min then
            new_value = callback_data.min
        end
        if callback_data.max and new_value > callback_data.max then
            new_value = callback_data.max
        end

        text_field.text = tostring(new_value)

        if callback_data.mod_name and callback_data.on_change then
            remote.call(callback_data.mod_name, callback_data.on_change, player, new_value, callback_data.data)
        end
        return
    end
end)

-- Handle entity destruction while GUI is open
local function close_invalid_guis()
    for player_index, gui_data in pairs(open_guis) do
        if gui_data.entity and not gui_data.entity.valid then
            local player = game.get_player(player_index)
            if player then
                local frame = player.gui.screen[FRAME_NAME]
                if frame and frame.valid then
                    frame.destroy()
                end
            end
            open_guis[player_index] = nil
        end
    end
end

-- Check for destroyed entities on common destruction events
script.on_event(defines.events.on_player_mined_entity, close_invalid_guis)
script.on_event(defines.events.on_robot_mined_entity, close_invalid_guis)
script.on_event(defines.events.on_entity_died, close_invalid_guis)

-- Handle periodic updates for open GUIs
script.on_event(defines.events.on_tick, function(event)
    for player_index, gui_data in pairs(open_guis) do
        local registration = gui_data.registration

        -- Skip if no update callback
        if not registration.on_update then
            goto continue
        end

        -- Check if enough ticks have passed
        local interval = registration.update_interval or 10
        if event.tick - gui_data.last_update_tick < interval then
            goto continue
        end

        -- Update timestamp
        gui_data.last_update_tick = event.tick

        -- Get player and content
        local player = game.get_player(player_index)
        if not player then
            goto continue
        end

        local frame = player.gui.screen[FRAME_NAME]
        if not frame or not frame.valid then
            goto continue
        end

        -- Find content container
        local inner_frame = frame.children[2]
        if not inner_frame or not inner_frame.valid then
            goto continue
        end

        local content = inner_frame[CONTENT_NAME]
        if not content or not content.valid then
            goto continue
        end

        -- Call update callback
        local entity = gui_data.entity
        if entity and entity.valid and registration.mod_name then
            remote.call(registration.mod_name, registration.on_update, content, entity, player)
        end

        ::continue::
    end
end)

-- Handle E key to close GUI (toggle-menu linked input)
script.on_event("entity-gui-lib-toggle", function(event)
    local player = game.get_player(event.player_index)
    if not player then
        return
    end

    local frame = player.gui.screen[FRAME_NAME]
    if frame and frame.valid then
        player.opened = nil
    end
end)

-- Initialize
script.on_init(function()
    storage.open_guis = open_guis
    storage.helper_callbacks = {}
end)

script.on_load(function()
    open_guis = storage.open_guis or {}
end)

-- Handle slider value changes
script.on_event(defines.events.on_gui_value_changed, function(event)
    local element = event.element
    if not element or not element.valid then return end
    if not element.name:find("^" .. GUI_PREFIX .. "slider_") then return end

    local callbacks = get_helper_callbacks()
    local callback_data = callbacks[element.name]
    if not callback_data then return end

    local player = game.get_player(event.player_index)
    if not player then return end

    -- Update value display if it exists
    local value_label_name = element.name:gsub("slider_", "slider_value_")
    local parent = element.parent
    if parent then
        for _, child in pairs(parent.children) do
            if child.name == value_label_name then
                child.caption = tostring(element.slider_value)
                break
            end
        end
    end

    -- Call user callback
    if callback_data.mod_name and callback_data.on_change then
        remote.call(callback_data.mod_name, callback_data.on_change, player, element.slider_value, callback_data.data)
    end
end)

-- Handle dropdown selection changes
script.on_event(defines.events.on_gui_selection_state_changed, function(event)
    local element = event.element
    if not element or not element.valid then return end
    if not element.name:find("^" .. GUI_PREFIX .. "dropdown_") then return end

    local callbacks = get_helper_callbacks()
    local callback_data = callbacks[element.name]
    if not callback_data then return end

    local player = game.get_player(event.player_index)
    if not player then return end

    if callback_data.mod_name and callback_data.on_change then
        local selected_index = element.selected_index
        local selected_value = callback_data.values and callback_data.values[selected_index] or selected_index
        remote.call(callback_data.mod_name, callback_data.on_change, player, selected_index, selected_value, callback_data.data)
    end
end)

-- Handle checkbox/toggle changes
script.on_event(defines.events.on_gui_checked_state_changed, function(event)
    local element = event.element
    if not element or not element.valid then return end
    if not element.name:find("^" .. GUI_PREFIX .. "toggle_") then return end

    local callbacks = get_helper_callbacks()
    local callback_data = callbacks[element.name]
    if not callback_data then return end

    local player = game.get_player(event.player_index)
    if not player then return end

    -- Handle mutual exclusion for radio button groups
    if callback_data.group_name and callback_data.mutual_exclusion and element.state then
        local parent = element.parent
        if parent then
            for _, child in pairs(parent.children) do
                if child.type == "radiobutton" or child.type == "checkbox" then
                    local child_data = callbacks[child.name]
                    if child_data and child_data.group_name == callback_data.group_name and child.name ~= element.name then
                        child.state = false
                    end
                end
            end
        end
    end

    if callback_data.mod_name and callback_data.on_change then
        remote.call(callback_data.mod_name, callback_data.on_change, player, element.state, callback_data.value, callback_data.data)
    end
end)

-- Handle number input button clicks and text changes
script.on_event(defines.events.on_gui_text_changed, function(event)
    local element = event.element
    if not element or not element.valid then return end
    if not element.name:find("^" .. GUI_PREFIX .. "number_input_") then return end

    local callbacks = get_helper_callbacks()
    local callback_data = callbacks[element.name]
    if not callback_data then return end

    local player = game.get_player(event.player_index)
    if not player then return end

    -- Validate and clamp the value
    local value = tonumber(element.text)
    if value then
        if callback_data.min and value < callback_data.min then
            value = callback_data.min
        end
        if callback_data.max and value > callback_data.max then
            value = callback_data.max
        end

        if callback_data.mod_name and callback_data.on_change then
            remote.call(callback_data.mod_name, callback_data.on_change, player, value, callback_data.data)
        end
    end
end)

-- Debug mode flag
local debug_mode = false

-- Remote interface for other mods
remote.add_interface("entity_gui_lib", {
    ---Register an entity for custom GUI replacement
    ---@param config table {mod_name: string, entity_name?: string, entity_type?: string, title?: LocalisedString, on_build: string, on_close?: string, priority?: number}
    register = function(config)
        if not config then
            error("entity_gui_lib.register: config is required")
        end

        if not config.mod_name then
            error("entity_gui_lib.register: mod_name is required")
        end

        if not config.entity_name and not config.entity_type then
            error("entity_gui_lib.register: entity_name or entity_type is required")
        end

        if not config.on_build then
            error("entity_gui_lib.register: on_build callback name is required")
        end

        local key = config.entity_name or config.entity_type
        local registration = {
            mod_name = config.mod_name,
            title = config.title,
            on_build = config.on_build,
            on_close = config.on_close,
            on_update = config.on_update,
            update_interval = config.update_interval or 10,
            priority = config.priority or 0,
            preview_size = config.preview_size,
        }

        -- Initialize list if needed
        if not registered_entities[key] then
            registered_entities[key] = {}
        end

        -- Remove existing registration from same mod
        local registrations = registered_entities[key]
        for i = #registrations, 1, -1 do
            if registrations[i].mod_name == config.mod_name then
                table.remove(registrations, i)
            end
        end

        -- Add new registration
        table.insert(registrations, registration)

        if debug_mode then
            log("[entity-gui-lib] Registered: " .. key .. " by " .. config.mod_name .. " (priority: " .. registration.priority .. ")")
        end
    end,

    ---Unregister an entity (removes all registrations from a mod for that entity)
    ---@param entity_name_or_type string
    ---@param mod_name string|nil If provided, only removes that mod's registration
    unregister = function(entity_name_or_type, mod_name)
        local registrations = registered_entities[entity_name_or_type]
        if not registrations then
            return
        end

        if mod_name then
            -- Remove only this mod's registration
            for i = #registrations, 1, -1 do
                if registrations[i].mod_name == mod_name then
                    table.remove(registrations, i)
                end
            end
        else
            -- Remove all registrations
            registered_entities[entity_name_or_type] = nil
        end
    end,

    ---Get all registrations for an entity (for conflict checking)
    ---@param entity_name_or_type string
    ---@return table[] Array of registrations sorted by priority (highest first)
    get_registrations = function(entity_name_or_type)
        local registrations = registered_entities[entity_name_or_type]
        if not registrations then
            return {}
        end

        -- Return a copy sorted by priority descending
        local result = {}
        for i, reg in ipairs(registrations) do
            result[i] = {
                mod_name = reg.mod_name,
                priority = reg.priority,
            }
        end
        table.sort(result, function(a, b) return a.priority > b.priority end)
        return result
    end,

    ---Refresh/rebuild the GUI content without closing
    ---@param player_index uint
    ---@return boolean success
    refresh = function(player_index)
        local gui_data = open_guis[player_index]
        if not gui_data then
            return false
        end

        local player = game.get_player(player_index)
        if not player then
            return false
        end

        local frame = player.gui.screen[FRAME_NAME]
        if not frame or not frame.valid then
            return false
        end

        -- Find content container
        local inner_frame = frame.children[2] -- entity_frame
        if not inner_frame or not inner_frame.valid then
            return false
        end

        local content = inner_frame[CONTENT_NAME]
        if not content or not content.valid then
            return false
        end

        -- Clear existing content
        content.clear()

        -- Rebuild content via callback
        local registration = gui_data.registration
        local entity = gui_data.entity
        if entity and entity.valid and registration.mod_name and registration.on_build then
            remote.call(registration.mod_name, registration.on_build, content, entity, player)
        end

        return true
    end,

    ---Get the content container for a player's open GUI
    ---@param player_index uint
    ---@return LuaGuiElement|nil
    get_content = function(player_index)
        local player = game.get_player(player_index)
        if not player then
            return nil
        end

        local frame = player.gui.screen[FRAME_NAME]
        if not frame or not frame.valid then
            return nil
        end

        return frame[CONTENT_NAME] or nil
    end,

    ---Get the entity for a player's open GUI
    ---@param player_index uint
    ---@return LuaEntity|nil
    get_entity = function(player_index)
        local gui_data = open_guis[player_index]
        if gui_data and gui_data.entity and gui_data.entity.valid then
            return gui_data.entity
        end
        return nil
    end,

    ---Close the custom GUI for a player
    ---@param player_index uint
    close = function(player_index)
        local player = game.get_player(player_index)
        if not player then
            return
        end

        local frame = player.gui.screen[FRAME_NAME]
        if frame and frame.valid then
            player.opened = nil
        end
    end,

    ---Create a tabbed pane helper
    ---@param container LuaGuiElement Parent container to add tabs to
    ---@param tabs table[] Array of {name: string, caption: LocalisedString}
    ---@return LuaGuiElement tabbed_pane, table<string, LuaGuiElement> tab_contents
    create_tabs = function(container, tabs)
        local tabbed_pane = container.add{
            type = "tabbed-pane",
            name = GUI_PREFIX .. "tabbed_pane",
        }

        local tab_contents = {}
        for _, tab_def in ipairs(tabs) do
            local tab = tabbed_pane.add{
                type = "tab",
                caption = tab_def.caption,
            }
            local content = tabbed_pane.add{
                type = "flow",
                name = tab_def.name,
                direction = "vertical",
            }
            tabbed_pane.add_tab(tab, content)
            tab_contents[tab_def.name] = content
        end

        return tabbed_pane, tab_contents
    end,

    ---Show a confirmation dialog
    ---@param player_index uint
    ---@param config table {title?: LocalisedString, message: LocalisedString, confirm_caption?: LocalisedString, cancel_caption?: LocalisedString, on_confirm: string, on_cancel?: string, mod_name: string, data?: any}
    show_confirmation = function(player_index, config)
        local player = game.get_player(player_index)
        if not player then
            return
        end

        -- Create modal frame
        local frame = player.gui.screen.add{
            type = "frame",
            name = GUI_PREFIX .. "confirmation",
            direction = "vertical",
        }
        frame.auto_center = true

        -- Title
        local titlebar = frame.add{
            type = "flow",
            direction = "horizontal",
        }
        titlebar.style.horizontal_spacing = 8

        titlebar.add{
            type = "label",
            caption = config.title or {"gui.confirmation"},
            style = "frame_title",
        }

        local filler = titlebar.add{
            type = "empty-widget",
            style = "draggable_space_header",
        }
        filler.style.height = 24
        filler.style.horizontally_stretchable = true
        filler.drag_target = frame

        -- Message
        local content = frame.add{
            type = "frame",
            style = "inside_shallow_frame_with_padding",
            direction = "vertical",
        }

        content.add{
            type = "label",
            caption = config.message,
        }

        -- Buttons
        local button_flow = frame.add{
            type = "flow",
            direction = "horizontal",
        }
        button_flow.style.top_margin = 8
        button_flow.style.horizontal_align = "right"
        button_flow.style.horizontally_stretchable = true

        button_flow.add{
            type = "button",
            name = GUI_PREFIX .. "confirm_cancel",
            caption = config.cancel_caption or {"gui.cancel"},
        }

        button_flow.add{
            type = "button",
            name = GUI_PREFIX .. "confirm_ok",
            caption = config.confirm_caption or {"gui.confirm"},
            style = "confirm_button",
        }

        -- Store callback info
        if not storage.confirmations then
            storage.confirmations = {}
        end
        storage.confirmations[player_index] = {
            mod_name = config.mod_name,
            on_confirm = config.on_confirm,
            on_cancel = config.on_cancel,
            data = config.data,
        }

        player.opened = frame
    end,

    ---Create a labeled slider with value display
    ---@param container LuaGuiElement Parent container
    ---@param config table {label?: LocalisedString, min: number, max: number, value?: number, step?: number, mod_name?: string, on_change?: string, data?: any}
    ---@return LuaGuiElement flow, LuaGuiElement slider
    create_slider = function(container, config)
        local id = get_next_helper_id()
        local slider_name = GUI_PREFIX .. "slider_" .. id
        local value_name = GUI_PREFIX .. "slider_value_" .. id

        local flow = container.add{
            type = "flow",
            direction = "horizontal",
        }
        flow.style.vertical_align = "center"
        flow.style.horizontal_spacing = 8

        if config.label then
            flow.add{
                type = "label",
                caption = config.label,
            }
        end

        local slider = flow.add{
            type = "slider",
            name = slider_name,
            minimum_value = config.min or 0,
            maximum_value = config.max or 100,
            value = config.value or config.min or 0,
            value_step = config.step or 1,
        }
        slider.style.horizontally_stretchable = true

        local value_label = flow.add{
            type = "label",
            name = value_name,
            caption = tostring(config.value or config.min or 0),
        }
        value_label.style.minimal_width = 40
        value_label.style.horizontal_align = "right"

        -- Store callback
        if config.mod_name and config.on_change then
            local callbacks = get_helper_callbacks()
            callbacks[slider_name] = {
                mod_name = config.mod_name,
                on_change = config.on_change,
                data = config.data,
            }
        end

        return flow, slider
    end,

    ---Create a number input with increment/decrement buttons
    ---@param container LuaGuiElement Parent container
    ---@param config table {label?: LocalisedString, value?: number, min?: number, max?: number, step?: number, mod_name?: string, on_change?: string, data?: any}
    ---@return LuaGuiElement flow, LuaGuiElement textfield
    create_number_input = function(container, config)
        local id = get_next_helper_id()
        local input_name = GUI_PREFIX .. "number_input_" .. id
        local dec_name = GUI_PREFIX .. "number_dec_" .. id
        local inc_name = GUI_PREFIX .. "number_inc_" .. id

        local flow = container.add{
            type = "flow",
            direction = "horizontal",
        }
        flow.style.vertical_align = "center"
        flow.style.horizontal_spacing = 4

        if config.label then
            local label = flow.add{
                type = "label",
                caption = config.label,
            }
            label.style.right_margin = 4
        end

        flow.add{
            type = "sprite-button",
            name = dec_name,
            sprite = "utility/left_arrow",
            style = "mini_button",
            tooltip = {"", "-", config.step or 1},
        }

        local text_field = flow.add{
            type = "textfield",
            name = input_name,
            text = tostring(config.value or config.min or 0),
            numeric = true,
            allow_decimal = true,
            allow_negative = (config.min or 0) < 0,
        }
        text_field.style.width = 60
        text_field.style.horizontal_align = "center"

        flow.add{
            type = "sprite-button",
            name = inc_name,
            sprite = "utility/right_arrow",
            style = "mini_button",
            tooltip = {"", "+", config.step or 1},
        }

        -- Store callback
        local callbacks = get_helper_callbacks()
        callbacks[input_name] = {
            mod_name = config.mod_name,
            on_change = config.on_change,
            min = config.min,
            max = config.max,
            step = config.step or 1,
            default = config.value or config.min or 0,
            data = config.data,
        }

        return flow, text_field
    end,

    ---Create a dropdown with callback handling
    ---@param container LuaGuiElement Parent container
    ---@param config table {label?: LocalisedString, items: LocalisedString[], values?: any[], selected_index?: number, mod_name?: string, on_change?: string, data?: any}
    ---@return LuaGuiElement flow, LuaGuiElement dropdown
    create_dropdown = function(container, config)
        local id = get_next_helper_id()
        local dropdown_name = GUI_PREFIX .. "dropdown_" .. id

        local flow = container.add{
            type = "flow",
            direction = "horizontal",
        }
        flow.style.vertical_align = "center"
        flow.style.horizontal_spacing = 8

        if config.label then
            flow.add{
                type = "label",
                caption = config.label,
            }
        end

        local dropdown = flow.add{
            type = "drop-down",
            name = dropdown_name,
            items = config.items or {},
            selected_index = config.selected_index or 1,
        }

        -- Store callback
        if config.mod_name and config.on_change then
            local callbacks = get_helper_callbacks()
            callbacks[dropdown_name] = {
                mod_name = config.mod_name,
                on_change = config.on_change,
                values = config.values,
                data = config.data,
            }
        end

        return flow, dropdown
    end,

    ---Create a toggle/checkbox group with optional mutual exclusion
    ---@param container LuaGuiElement Parent container
    ---@param config table {label?: LocalisedString, options: table[], use_radiobuttons?: boolean, mutual_exclusion?: boolean, mod_name?: string, on_change?: string, data?: any}
    ---Options format: {caption: LocalisedString, value: any, state?: boolean, tooltip?: LocalisedString}
    ---@return LuaGuiElement flow, table<string, LuaGuiElement> toggles
    create_toggle_group = function(container, config)
        local id = get_next_helper_id()
        local group_name = GUI_PREFIX .. "toggle_group_" .. id

        local outer_flow = container.add{
            type = "flow",
            direction = "vertical",
        }
        outer_flow.style.vertical_spacing = 4

        if config.label then
            outer_flow.add{
                type = "label",
                caption = config.label,
                style = "caption_label",
            }
        end

        local toggle_flow = outer_flow.add{
            type = "flow",
            direction = config.horizontal and "horizontal" or "vertical",
        }
        if config.horizontal then
            toggle_flow.style.horizontal_spacing = 8
        else
            toggle_flow.style.vertical_spacing = 4
        end

        local toggles = {}
        local use_radio = config.use_radiobuttons or config.mutual_exclusion

        for i, option in ipairs(config.options or {}) do
            local toggle_name = GUI_PREFIX .. "toggle_" .. id .. "_" .. i

            local toggle = toggle_flow.add{
                type = use_radio and "radiobutton" or "checkbox",
                name = toggle_name,
                caption = option.caption,
                state = option.state or false,
                tooltip = option.tooltip,
            }

            toggles[option.value or i] = toggle

            -- Store callback for each toggle
            local callbacks = get_helper_callbacks()
            callbacks[toggle_name] = {
                mod_name = config.mod_name,
                on_change = config.on_change,
                value = option.value or i,
                group_name = group_name,
                mutual_exclusion = config.mutual_exclusion,
                data = config.data,
            }
        end

        return outer_flow, toggles
    end,

    ---Enable or disable debug mode
    ---@param enabled boolean
    set_debug_mode = function(enabled)
        debug_mode = enabled
        if enabled then
            log("[entity-gui-lib] Debug mode enabled")
        end
    end,

    ---Check if debug mode is enabled
    ---@return boolean
    is_debug_mode = function()
        return debug_mode
    end,
})
