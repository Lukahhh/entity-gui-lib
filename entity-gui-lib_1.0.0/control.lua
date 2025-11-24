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
    }
    title.drag_target = frame

    -- Drag handle (filler)
    local filler = titlebar.add{
        type = "empty-widget",
        style = "draggable_space_header",
    }
    filler.style.height = 24
    filler.style.horizontally_stretchable = true
    filler.drag_target = frame

    -- Close button
    titlebar.add{
        type = "sprite-button",
        name = GUI_PREFIX .. "close_button",
        sprite = "utility/close",
        style = "close_button",
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
    preview.style.height = 148
    preview.style.width = 148

    -- Status section
    local status_flow = preview_flow.add{
        type = "flow",
        direction = "vertical",
    }
    status_flow.style.vertical_spacing = 4

    -- Entity status
    local status = entity.status
    local status_sprite = "utility/status_working"
    local status_caption = {"entity-status.working"}

    if status then
        if status == defines.entity_status.no_power then
            status_sprite = "utility/status_not_working"
            status_caption = {"entity-status.no-power"}
        elseif status == defines.entity_status.low_power then
            status_sprite = "utility/status_yellow"
            status_caption = {"entity-status.low-power"}
        elseif status == defines.entity_status.no_fuel then
            status_sprite = "utility/status_not_working"
            status_caption = {"entity-status.no-fuel"}
        elseif status == defines.entity_status.disabled_by_control_behavior then
            status_sprite = "utility/status_not_working"
            status_caption = {"entity-status.disabled"}
        elseif status == defines.entity_status.disabled_by_script then
            status_sprite = "utility/status_not_working"
            status_caption = {"entity-status.disabled-by-script"}
        elseif status == defines.entity_status.marked_for_deconstruction then
            status_sprite = "utility/status_not_working"
            status_caption = {"entity-status.marked-for-deconstruction"}
        elseif status == defines.entity_status.no_recipe then
            status_sprite = "utility/status_not_working"
            status_caption = {"entity-status.no-recipe"}
        elseif status == defines.entity_status.no_ingredients then
            status_sprite = "utility/status_not_working"
            status_caption = {"entity-status.no-ingredients"}
        elseif status == defines.entity_status.no_input_fluid then
            status_sprite = "utility/status_not_working"
            status_caption = {"entity-status.no-input-fluid"}
        elseif status == defines.entity_status.no_research_in_progress then
            status_sprite = "utility/status_not_working"
            status_caption = {"entity-status.no-research-in-progress"}
        elseif status == defines.entity_status.no_minable_resources then
            status_sprite = "utility/status_not_working"
            status_caption = {"entity-status.no-minable-resources"}
        elseif status == defines.entity_status.waiting_for_source_items then
            status_sprite = "utility/status_yellow"
            status_caption = {"entity-status.waiting-for-source-items"}
        elseif status == defines.entity_status.waiting_for_space_in_destination then
            status_sprite = "utility/status_yellow"
            status_caption = {"entity-status.waiting-for-space-in-destination"}
        elseif status == defines.entity_status.charging then
            status_sprite = "utility/status_yellow"
            status_caption = {"entity-status.charging"}
        elseif status == defines.entity_status.discharging then
            status_sprite = "utility/status_working"
            status_caption = {"entity-status.discharging"}
        elseif status == defines.entity_status.fully_charged then
            status_sprite = "utility/status_working"
            status_caption = {"entity-status.fully-charged"}
        end
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
end)

script.on_event(defines.events.on_gui_closed, function(event)
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

script.on_event(defines.events.on_gui_click, function(event)
    local element = event.element
    if not element or not element.valid then
        return
    end

    if element.name ~= GUI_PREFIX .. "close_button" then
        return
    end

    local player = game.get_player(event.player_index)
    if not player then
        return
    end

    -- Close the GUI
    local frame = player.gui.screen[FRAME_NAME]
    if frame and frame.valid then
        player.opened = nil
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
end)

script.on_load(function()
    open_guis = storage.open_guis or {}
end)

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
            priority = config.priority or 0,
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
})
