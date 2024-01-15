local M = {}

local util = require('detour.util')
local internal = require('detour.internal')

local plugin_augroup = "detour-plugin"
vim.api.nvim_create_augroup(plugin_augroup, { clear = true })

function M.setup_autocmds()
    if internal.config.keep_focus_on_top then
        vim.api.nvim_create_autocmd({"WinEnter"}, {
            group = plugin_augroup,
            callback = function ()
                vim.fn.win_gotoid(util.find_top_popup())
            end,
        })

        vim.api.nvim_create_autocmd({"User"}, {
            pattern = "WinEnter",
            group = plugin_augroup,
            callback = function ()
                vim.fn.win_gotoid(util.find_top_popup())
            end,
        })
    end
end

return M
