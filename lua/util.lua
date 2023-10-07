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

return M
