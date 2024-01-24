local M = {}

local util = require('detour.util')

function M.ShowFileNameInTitle(window_id)
    vim.api.nvim_win_set_config(window_id,
        vim.tbl_extend("force",
        vim.api.nvim_win_get_config(window_id),
        { title = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(window_id)), ":.") }))

    vim.api.nvim_create_autocmd({"BufEnter"}, {
        group = util.construct_augroup_name(window_id),
        callback = function ()
            vim.api.nvim_win_set_config(window_id,
            vim.tbl_extend("force",
                vim.api.nvim_win_get_config(window_id),
                { title = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(window_id)), ":.") }))
        end
    })
end

return M
