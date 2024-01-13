local M = {}

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

return M
