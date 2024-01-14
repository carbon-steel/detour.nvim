local M = {}

local util = require('detour.util')
local MIN_POPUP_HEIGHT = 3 -- border (2) + text (1)
local MIN_POPUP_WIDTH = 3 -- border (2) + text (1)

local popup_to_covered_windows = {}

local function is_statusline_global()
    if vim.o.laststatus == 3 then
        return false -- the statusline is global. No specific window has it.
    end
end

local function construct_window_opts(coverable_windows, tab_id)
    local roots = {}
    for _, window_id in ipairs(vim.api.nvim_tabpage_list_wins(tab_id)) do
        if not util.is_floating(window_id) then
            table.insert(roots, window_id)
        end
    end
    --print("window_ids " .. vim.inspect(window_ids))

    local uncoverable_windows = {}
    for _, root in ipairs(roots) do
        if not util.contains_element(coverable_windows, root) then
            table.insert(uncoverable_windows, root)
        end
    end
    --print("uncoverable_windows " .. vim.inspect(uncoverable_windows))
    local horizontals = {}
    local verticals = {}

    for _, root in ipairs(roots) do
        local top, bottom, left, right = util.get_text_area_dimensions(root)
        horizontals[top] = 1
        horizontals[bottom] = 1
        verticals[left] = 1
        verticals[right] = 1
    end

    local floors = {}
    local sides = {}

    for top, _ in pairs(horizontals) do
        for bottom, _ in pairs(horizontals) do
            if top + MIN_POPUP_HEIGHT <= bottom then
                table.insert(floors, {top, bottom})
            end
        end
    end

    for left, _ in pairs(verticals) do
        for right, _ in pairs(verticals) do
            if left + MIN_POPUP_WIDTH <= right then
                table.insert(sides, {left, right})
            end
        end
    end

    local max_area = 0
    local dimensions = nil
    for _, curr_floors in ipairs(floors) do
        local top, bottom = unpack(curr_floors)
        for _, curr_sides in ipairs(sides) do
            local left, right = unpack(curr_sides)
            local legal = true
            for _, uncoverable_window in ipairs(uncoverable_windows) do
                local uncoverable_top, uncoverable_bottom, uncoverable_left, uncoverable_right = util.get_text_area_dimensions(uncoverable_window)
                if not is_statusline_global() then -- we have to worry about statuslines
                    -- The fact that we're starting with text area dimensions means that all of the rectangles we are working with do not include statuslines.
                    -- This means that we need to avoid inadvertantly covering a window's status line.
                    -- Neovim can be configured to only show statuslines when there are multiple windows on the screen but we can ignore that because this loop only runs when there are multiple windows on the screen.
                    uncoverable_top = uncoverable_top - 1 -- don't cover above window's statusline
                    uncoverable_bottom = uncoverable_bottom + 1 -- don't cover this window's statusline
                end
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
    local width = right - left
    local height = bottom - top

    if height < MIN_POPUP_HEIGHT then
        vim.api.nvim_err_writeln("[detour.nvim] (please file a github issue!) height is supposed to be at least " .. MIN_POPUP_HEIGHT)
        return nil
    end
    if width < MIN_POPUP_WIDTH then
        vim.api.nvim_err_writeln("[detour.nvim] (please file a github issue!) width is supposed to be at least .." .. MIN_POPUP_WIDTH)
        return nil
    end

    -- If a window's height extends below the UI, the window's border gets cut off.
    -- If a window's width extends beyond the UI, the window's border still shows up at the end of the UI.
    -- Using a border adds 2 to the window's height and width.
    local window_opts =  {
        relative = "editor",
        row = top,
        col = left,
        width = width - 2, -- create some space for borders
        height = height - 2, -- create some space for borders
        border = "rounded",
        zindex = 1,
    }

    if window_opts.width > 40 then
        window_opts.width = window_opts.width - 4
        window_opts.col = window_opts.col + 2
    end

    if window_opts.height >= 7 then
        window_opts.height = window_opts.height - 2
        window_opts.row = window_opts.row + 1
    end

    return window_opts
end

local function construct_nest(parent, layer)
    local top, bottom, left, right = util.get_text_area_dimensions(parent)
    local width = right - left
    local height = bottom - top
    local border = "rounded"
    if height >= 3 then
        height = height - 2
        top = top + 1
    end
    if width >= 3 then
        width = width - 2
        left = left + 1
    end
    return {
        relative = "editor",
        row = top,
        col = left,
        width = width,
        height = height,
        border = border,
        zindex = layer
    }
end

local function construct_augroup_name(window_id)
    return "detour-"..window_id
end

-- Needs to be idempotent
local function teardownDetour(window_id)
    vim.api.nvim_del_augroup_by_name(construct_augroup_name(window_id))
    popup_to_covered_windows[window_id] = nil
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
    if window_opts ~= nil then
        vim.api.nvim_win_set_config(window_id, window_opts)
        vim.cmd.doautocmd("User PopupResized"..stringify(window_id))
    end
end

local function nested_popup()
    local parent = vim.api.nvim_get_current_win()
    local tab_id = vim.api.nvim_get_current_tabpage()

    if not is_available(parent) then
        vim.api.nvim_err_writeln("[detour.nvim] This popup already has a child nested inside it:" .. parent)
        return false
    end

    local parent_zindex = util.get_maybe_zindex(parent) or 0
    local window_opts = construct_nest(parent, parent_zindex + 1)

    local child = vim.api.nvim_open_win(vim.api.nvim_win_get_buf(0), true, window_opts)
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
            if vim.tbl_contains(vim.api.nvim_tabpage_list_wins(tab_id), parent) then
                vim.fn.win_gotoid(parent)
            end
        end
    })

    vim.api.nvim_create_autocmd({"WinClosed"}, {
        group = augroup_id,
        pattern = "" .. parent,
        callback = function ()
            vim.api.nvim_win_close(child, false)
            -- Even if `nested` is set to true, WinClosed does not trigger itself.
            vim.cmd.doautocmd("WinClosed ".. child)
        end,
    })
    -- We're running this to make sure initializing popups runs the same code path as updating popups
    -- We make sure to do this after all state and autocmds are set.
    resize_popup(child, window_opts)
    return true
end

local function popup(bufnr, coverable_windows)
    local parent = vim.api.nvim_get_current_win()
    if util.is_floating(parent) then
        return nested_popup()
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
        return false
    end

    for _, window in ipairs(coverable_windows) do
        if util.is_floating(window) then
            vim.api.nvim_err_writeln("[detour.nvim] No floating windows allowed in base (ie, non-nested) popup" .. window)
            return false
        end

        if not is_available(window) then
            vim.api.nvim_err_writeln("[detour.nvim] This window is already reserved by another popup:" .. window)
            return false
        end
    end

    local window_opts = construct_window_opts(coverable_windows, tab_id)
    if window_opts == nil then
        return false
    end
    local popup_id = vim.api.nvim_open_win(bufnr, true, window_opts)
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
            for _, base in ipairs(coverable_windows) do
                if vim.tbl_contains(vim.api.nvim_tabpage_list_wins(tab_id), base) then
                    vim.fn.win_gotoid(base)
                    return
                end
            end
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
                    vim.api.nvim_win_close(popup_id, false)
                    -- Even if `nested` is set to true, WinClosed does not trigger itself.
                    vim.cmd.doautocmd("WinClosed ".. popup_id)
                end
            end,
        })
    end
    -- We're running this to make sure initializing popups runs the same code path as updating popups
    -- We make sure to do this after all state and autocmds are set.
    resize_popup(popup_id, window_opts)
    return true
end

M.Detour = function ()
    return popup(vim.api.nvim_get_current_buf())
end

M.DetourCurrentWindow = function ()
    return popup(vim.api.nvim_get_current_buf(), {vim.api.nvim_get_current_win()})
end

return M
