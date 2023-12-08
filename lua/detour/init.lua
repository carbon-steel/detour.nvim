local M = {}

local util = require('detour.util')

local popup_to_covered_windows = {}
local function construct_window_opts(coverable_windows, tab_id)
    local roots = {}
    for _, window_id in ipairs(vim.api.nvim_tabpage_list_wins(tab_id)) do
        if not util.is_floating(window_id) then
            table.insert(roots, window_id)
        end
    end
    --print("window_ids " .. vim.inspect(window_ids))

    local uncoverable_windows = {}
    for _, window_id in ipairs(roots) do
        if not util.contains_element(coverable_windows, window_id) then
            table.insert(uncoverable_windows, window_id)
        end
    end
    --print("uncoverable_windows " .. vim.inspect(uncoverable_windows))
    local horizontals = {}
    local verticals = {}

    for _, window_id in ipairs(roots) do
        local top, bottom, left, right = util.get_window_coordinates(window_id)
        horizontals[top] = 1
        horizontals[bottom] = 1
        verticals[left] = 1
        verticals[right] = 1
    end

    --print( "horizontals " .. vim.inspect(horizontals))
    --print( "verticals " .. vim.inspect(verticals))

    local floors = {}
    local sides = {}

    for top, _ in pairs(horizontals) do
        for bottom, _ in pairs(horizontals) do
            if top < bottom then
                table.insert(floors, {top, bottom})
            end
        end
    end

    for left, _ in pairs(verticals) do
        for right, _ in pairs(verticals) do
            if left < right then
                table.insert(sides, {left, right})
            end
        end
    end

    --print( "floors " .. vim.inspect(floors))
    --print( "sides " .. vim.inspect(sides))

    local max_area = 0
    local dimensions = nil
    for _, curr_floors in ipairs(floors) do
        local top, bottom = unpack(curr_floors)
        for _, curr_sides in ipairs(sides) do
            local left, right = unpack(curr_sides)
            local legal = true
            for _, uncoverable_window in ipairs(uncoverable_windows) do
                local uncoverable_top, uncoverable_bottom, uncoverable_left, uncoverable_right = util.get_window_coordinates(uncoverable_window)
                local lowest_top = math.max(top, uncoverable_top)
                local highest_bottom = math.min(bottom, uncoverable_bottom)
                local rightest_left = math.max(left, uncoverable_left)
                local leftest_right = math.min(right, uncoverable_right)
                if (lowest_top < highest_bottom) and (rightest_left < leftest_right) then
                    --print("(" .. top .. "," .. left .. ")x(" .. bottom .. "," .. right .. ")")
                    --print("vs (" .. uncoverable_top .. "," .. uncoverable_left .. ")x(" .. uncoverable_bottom .. "," .. uncoverable_right .. ")")

                    --print("illegal!")
                    legal = false
                end
            end

            local area = (bottom - top) * (right - left)
            if legal and (area > max_area) then
                dimensions = {top, bottom, left, right}
                max_area = area
            end
        end
    end

    if dimensions == nil then
        vim.api.nvim_err_writeln("[detour.nvim] was unable to find a spot to create a popup.")
        return nil
    end

    local top, bottom, left, right = unpack(dimensions)
    local width = right - left - 1
    local height = bottom - top - 1
    if width > 20 then
        width = width - 4
        left = left + 2
    end
    if height > 14 then
        height = height - 4
        top = top + 2
    end
    return {
        relative = "editor",
        row = top,
        col = left,
        width = width,
        height = height,
        border = "rounded",
        zindex = 1,
    }
end

local function construct_nest(parent, layer)
    local top, bottom, left, right = util.get_window_coordinates(parent)
    local width = right - left - 2
    local height = bottom - top - 2
    return {
        relative = "editor",
        row = top + 1,
        col = left + 1,
        width = width,
        height = height,
        border = "rounded",
        zindex = layer
    }
end

local function construct_augroup_name(window_id)
    return "detour-"..window_id
end

local popup_to_layer = {}
-- Needs to be idempotent
local function teardownDetour(window_id)
    vim.api.nvim_del_augroup_by_name(construct_augroup_name(window_id))
    vim.api.nvim_win_close(window_id, false)
    popup_to_covered_windows[window_id] = nil
    popup_to_layer[window_id] = nil
end

local function stringify(number)
    local base = string.byte("a")
    local values = {}
    for digit in (""..number):gmatch(".") do
        values[#values+1] = tonumber(digit) + base
    end
    return string.char(unpack(values))
end

local function is_available(window)
    for _, unavailable_windows in pairs(popup_to_covered_windows) do
        if util.contains_value(unavailable_windows, window) then
            return false
        end
    end
    return true
end

local function resize_popup(window_id, window_opts)
    vim.api.nvim_win_set_config(window_id, window_opts)
    vim.cmd.doautocmd("User PopupResized"..stringify(window_id))
end

local function nested_popup()
    local parent = vim.api.nvim_get_current_win()

    if not is_available(parent) then
        vim.api.nvim_err_writeln("[detour.nvim] This popup already has a child nested inside it:" .. parent)
        return
    end

    local window_opts = construct_nest(parent, popup_to_layer[parent] + 1)
    local child = vim.api.nvim_open_win(vim.api.nvim_win_get_buf(0), true, window_opts)
    popup_to_layer[child] =  popup_to_layer[parent] + 1
    popup_to_covered_windows[child] = { parent }
    local augroup_id = vim.api.nvim_create_augroup(construct_augroup_name(child), {})
    vim.api.nvim_create_autocmd({"User"}, {
        pattern = "PopupResized"..stringify(parent),
        group = augroup_id,
        callback = function ()
            local new_window_opts = construct_nest(parent)
            resize_popup(child, new_window_opts)
        end
    })
    vim.api.nvim_create_autocmd({"WinClosed"}, {
        group = augroup_id,
        pattern = "" .. child,
        callback = function ()
            teardownDetour(child)
        end
    })

    vim.api.nvim_create_autocmd({"WinClosed"}, {
        group = augroup_id,
        pattern = "" .. parent,
        callback = function ()
            vim.cmd.doautocmd("WinClosed "..child)
        end
    })
end

local function popup(bufnr, coverable_windows)
    local parent = vim.api.nvim_get_current_win()
    if util.is_floating(parent) then
        nested_popup()
        return
    end
    local tab_id = vim.api.nvim_get_current_tabpage()
    if coverable_windows == nil then
        coverable_windows = {}
        for _, window in ipairs(vim.api.nvim_tabpage_list_wins(tab_id)) do
            if not util.is_floating(window) and is_available(window) then
                table.insert(coverable_windows, window)
            end
        end
    end

    if #coverable_windows == 0 then
        vim.api.nvim_err_writeln("[detour.nvim] No windows provided in coverable_windows.")
        return
    end

    for _, window in ipairs(coverable_windows) do
        if util.is_floating(window) then
            vim.api.nvim_err_writeln("[detour.nvim] No floating windows allowed in base (ie, non-nested) popup" .. window)
            return
        end

        if not is_available(window) then
            vim.api.nvim_err_writeln("[detour.nvim] This window is already reserved by another popup:" .. window)
            return
        end
    end

    local window_opts = construct_window_opts(coverable_windows, tab_id)
    local popup_id = vim.api.nvim_open_win(bufnr, true, window_opts)
    popup_to_layer[popup_id] = 1
    popup_to_covered_windows[popup_id] = coverable_windows
    local augroup_id = vim.api.nvim_create_augroup(construct_augroup_name(popup_id), {})
    vim.api.nvim_create_autocmd({"WinResized"}, {
        group = augroup_id,
        callback = function ()
            for _, x in ipairs(vim.v.event.windows) do
                if util.contains_element(vim.api.nvim_tabpage_list_wins(tab_id), x) then
                    local new_window_opts = construct_window_opts(coverable_windows, tab_id)
                    resize_popup(popup_id, new_window_opts)
                    break
                end
            end
        end
    })
    vim.api.nvim_create_autocmd({"WinClosed"}, {
        group = augroup_id,
        pattern = "" .. popup_id,
        callback = function ()
            teardownDetour(popup_id)
        end
    })

    for _, triggering_window in ipairs(coverable_windows) do
        vim.api.nvim_create_autocmd({"WinClosed"}, {
            group = augroup_id,
            pattern = "" .. triggering_window,
            callback = function ()
                local all_closed = true
                local open_windows = vim.api.nvim_tabpage_list_wins(tab_id)
                for _, covered_window in ipairs(coverable_windows) do
                    if util.contains_element(open_windows, covered_window) and covered_window ~= triggering_window then
                        all_closed = false
                    end
                end

                if all_closed then
                    --print("tearing down")
                    teardownDetour(popup_id)
                    vim.cmd.doautocmd("WinClosed ".. popup_id)
                end
            end
        })
    end
end

M.Detour = function ()
    popup(vim.api.nvim_get_current_buf())
end

M.DetourCurrentWindow = function ()
    popup(vim.api.nvim_get_current_buf(), {vim.api.nvim_get_current_win()})
end

return M
