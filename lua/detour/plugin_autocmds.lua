local util = require('detour.util')
local config = require('detour.internal').config

local plugin_augroup = "detour-plugin"
vim.api.nvim_create_augroup(plugin_augroup, { clear = true })

if config.focus_on_top then
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

return {}
