local M = {}

local util = require('util')

local popup_to_covered_windows = {}
local last_constructed = {}
local function construct_window_opts(coverable_windows, tab_id)
    last_constructed["coverable_windows"] = coverable_windows
    last_constructed["tab_id"] = tab_id
    local window_ids = {}
    for _, window_id in ipairs(vim.api.nvim_tabpage_list_wins(tab_id)) do
        if not util.is_floating(window_id) then
            table.insert(window_ids, window_id)
        end
    end
    --print("window_ids " .. vim.inspect(window_ids))

    local uncoverable_windows = {}
    for _, window_id in ipairs(window_ids) do
        if not util.contains_element(coverable_windows, window_id) then
            table.insert(uncoverable_windows, window_id)
        end
    end
    --print("uncoverable_windows " .. vim.inspect(uncoverable_windows))
    local horizontals = {}
    local verticals = {}

    for _, window_id in ipairs(window_ids) do
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
    }
end

local function construct_augroup_name(window_id)
    return "detour-"..window_id
end

local function teardownDetour(window_id)
    vim.api.nvim_del_augroup_by_name(construct_augroup_name(window_id))
    vim.api.nvim_win_close(window_id, false)
    popup_to_covered_windows[window_id] = nil
end

local function popup(bufnr)
    local tab_id = vim.api.nvim_get_current_tabpage()
    local covered_windows = {}
    for _, window in ipairs(vim.api.nvim_tabpage_list_wins(tab_id)) do
        local legal = true
        for _, unavailable_windows in pairs(popup_to_covered_windows) do
            if util.contains_value(unavailable_windows, window) then
                legal = false
            end
        end
        if legal then
            table.insert(covered_windows, window)
        end
    end

    local window_opts = construct_window_opts(covered_windows, tab_id)
    local popup_id = vim.api.nvim_open_win(bufnr, true, window_opts)
    popup_to_covered_windows[popup_id] = covered_windows
    local augroup_id = vim.api.nvim_create_augroup(construct_augroup_name(popup_id), {})
    vim.api.nvim_create_autocmd({"WinResized"}, {
        group = augroup_id,
        callback = function ()
            for x, _ in ipairs(vim.v.event.windows) do
                if util.contains_element(covered_windows, vim.fn.win_getid(x)) then
                    local new_window_opts = construct_window_opts(covered_windows, tab_id)
                    vim.api.nvim_win_set_config(popup_id, new_window_opts)
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

    for _, triggering_window in ipairs(covered_windows) do
        vim.api.nvim_create_autocmd({"WinClosed"}, {
            group = augroup_id,
            pattern = "" .. triggering_window,
            callback = function ()
                local all_closed = true
                local open_windows = vim.api.nvim_tabpage_list_wins(tab_id)
                for _, covered_window in ipairs(covered_windows) do
                    if util.contains_element(open_windows, covered_window) and covered_window ~= triggering_window then
                        all_closed = false
                    end
                end

                if all_closed then
                    --print("tearing down")
                    teardownDetour(popup_id)
                end
            end
        })
    end
end

M.Detour = function ()
    popup(vim.api.nvim_get_current_buf())
end

vim.api.nvim_create_user_command("Detour", M.Detour, {})
vim.api.nvim_create_user_command("DetourDebug", function ()
    print("popup_to_covered_windows:\n"..vim.inspect(popup_to_covered_windows))
    print("last_constructed\n"..vim.inspect(last_constructed))
end, {})

return M
