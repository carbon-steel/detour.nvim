local M = {}

local util = require('detour.util')

local function update_title(window_id)
    -- Assumption: window_id is not closed as this was triggered from the fact that we are redrawing this window.
    local buffer_id = vim.api.nvim_win_get_buf(window_id)
    local path = vim.api.nvim_buf_get_name(buffer_id)
    local title = vim.fn.fnamemodify(path, ":.")
    vim.api.nvim_win_set_config(window_id,
        vim.tbl_extend("force",
        vim.api.nvim_win_get_config(window_id),
        { title = title }))
end

function M.ShowPathInTitle(window_id)
    require('detour.show_path_in_title')
    update_title(window_id)

    vim.api.nvim_create_autocmd({"User"}, {
        pattern = "DetourUpdateTitle"..util.stringify(window_id),
        group = util.construct_augroup_name(window_id),
        callback = function () update_title(window_id) end
    })
end

return M
