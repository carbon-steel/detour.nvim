local M = {}

local internal = require('detour.internal')

function M.Set (list)
    local set = {}
    for _, l in ipairs(list) do set[l] = true end
    return set
end

function M.contains_element(array, target)
    for _, value in ipairs(array) do
        if value == target then
            return true
        end
    end
    return false
end

function M.contains_key(array, target)
    for key, _ in pairs(array) do
        if key == target then
            return true
        end
    end
    return false
end

function M.contains_value(array, target)
    for _, value in pairs(array) do
        if value == target then
            return true
        end
    end
    return false
end

-- Returns the positions of top, bottom, left, and right of a given window's text area.
-- The statusline is not included in the text area.
-- bottom and right are exclusive
function M.get_text_area_dimensions(window_id)
    local top, left = unpack(vim.api.nvim_win_get_position(window_id))
    local bottom = top + vim.api.nvim_win_get_height(window_id)
    local right = left + vim.api.nvim_win_get_width(window_id)
    return top, bottom, left, right
end

function M.is_floating(window_id)
    return vim.api.nvim_win_get_config(window_id).relative ~= ''
end

-- Returns the zindex for the given window, if floating, otherwise nil.
function M.get_maybe_zindex(window_id)
    return vim.api.nvim_win_get_config(window_id).zindex
end

local function overlap_helper(positions_a, positions_b)
    local top_a, bottom_a, left_a, right_a = unpack(positions_a)
    local top_b, bottom_b, left_b, right_b = unpack(positions_b)
    if math.max(left_a, left_b) >= math.min(right_a, right_b) then
        return false
    end

    if math.max(top_a, top_b) >= math.min(bottom_a, bottom_b) then
        return false
    end

    return true
end

function M.overlap(window_a, window_b)
    return overlap_helper({M.get_text_area_dimensions(window_a)}, {M.get_text_area_dimensions(window_b)})
end

function M.find_top_popup()
    local window_id = vim.api.nvim_get_current_win()
    local all_covered_windows = vim.tbl_flatten(vim.tbl_values(internal.popup_to_covered_windows))
    for popup, _ in pairs(internal.popup_to_covered_windows) do
        if not vim.tbl_contains(all_covered_windows, popup) -- ignore popups with popups nested in them
            and vim.tbl_contains(M.find_covered_bases(popup), window_id) then
            return popup
        end
    end
    return window_id -- no popup that covers the current window was found
end

-- Finds all base windows that are covered by the provided popup.
-- If the provided window is not a popup, returns the given argument.
function M.find_covered_bases(window_id)
    local temp_id = window_id
    local covered_bases = nil
    while vim.tbl_get(internal.popup_to_covered_windows, temp_id) do
        covered_bases = internal.popup_to_covered_windows[temp_id]
        if #covered_bases == 0 then
            assert(false, "[detour.nvim] There should never be an empty array in popup_to_covered_windows.")
        end
        -- We iterate on only the first covered window because there are two cases:
        -- A: there is exactly one covered window and it's another detour.
        -- B: there is one or more covered windows and none of them are detours. We've found our covered base windows. Hence, this would be the last iteration of this loop.
        temp_id = covered_bases[1]
    end

    -- This covers the case where the window_id is not a detour popup and we never enter the above loop.
    if covered_bases == nil then
        covered_bases = {window_id}
    end

    return vim.tbl_filter(function (base)
        return vim.tbl_contains(vim.api.nvim_list_wins(), base) and M.overlap(base, window_id)
    end, covered_bases)
end

function M.is_open(window_id)
    return vim.tbl_contains(vim.api.nvim_list_wins(), window_id)
end

return M
