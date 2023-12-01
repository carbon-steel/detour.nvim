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

function M.get_window_coordinates(window_id)
    local top, left = unpack(vim.api.nvim_win_get_position(window_id))
    local bottom = top + vim.api.nvim_win_get_height(window_id)
    local right = left + vim.api.nvim_win_get_width(window_id)
    return top, bottom, left, right
end

function M.is_floating(window_id)
    return vim.api.nvim_win_get_config(window_id).relative ~= ''
end

return M
