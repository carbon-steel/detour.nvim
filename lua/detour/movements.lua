local M = {}

local util = require('detour.util')

-- The movements module introduces backward-incompatible changes. Users who `require` this module will have the new autocmds that allow for "popup aware" window movements. Those who do not will stay with the previous behavior. This approach allows users to opt-in to the new behavior instead of having the behavior change from under their feet.

local module_augroup = "detour-movements"
vim.api.nvim_create_augroup(module_augroup, { clear = true })

vim.api.nvim_create_autocmd({"WinEnter"}, {
    group = module_augroup,
    callback = function ()
        if not vim.g.manually_switching_window_focus then
            vim.cmd.doautocmd("User DetourWinEnter")
        end
    end,
})

vim.api.nvim_create_autocmd({"User"}, {
    pattern = "DetourWinEnter",
    group = module_augroup,
    callback = function ()
        vim.fn.win_gotoid(util.find_top_popup())
    end,
})

function M.DetourWinCmdL()
    local covered_bases = util.find_covered_bases(vim.api.nvim_get_current_win())
    local rightest_base = covered_bases[1]
    for _, covered_base in ipairs(covered_bases) do
        local _, _, _, right_a = util.get_text_area_dimensions(covered_base)
        local _, _, _, right_b = util.get_text_area_dimensions(rightest_base)
        if right_a > right_b then
            rightest_base = covered_base
        end
    end
    vim.g.manually_switching_window_focus = true
    vim.fn.win_gotoid(rightest_base)
    vim.g.manually_switching_window_focus = false
    vim.cmd.wincmd('l')
    vim.api.nvim_exec_autocmds("User", { pattern = "DetourWinEnter" }) -- This is necessary as the above wincmd is not guaranteed to trigger WinEnter (as any actual window movement may not occur)
end

function M.DetourWinCmdH()
    local covered_bases = util.find_covered_bases(vim.api.nvim_get_current_win())
    local leftest_base = covered_bases[1]
    for _, covered_base in ipairs(covered_bases) do
        local _, _, left_a, _ = util.get_text_area_dimensions(covered_base)
        local _, _, left_b, _ = util.get_text_area_dimensions(leftest_base)
        if left_a < left_b then
            leftest_base = covered_base
        end
    end
    vim.g.manually_switching_window_focus = true
    vim.fn.win_gotoid(leftest_base)
    vim.g.manually_switching_window_focus = false
    vim.cmd.wincmd('h')
    vim.cmd.doautocmd("User DetourWinEnter") -- This is necessary as the above wincmd is not guaranteed to trigger WinEnter (as any actual window movement may not occur)
end

function M.DetourWinCmdJ()
    local covered_bases = util.find_covered_bases(vim.api.nvim_get_current_win())
    local bottom_base = covered_bases[1]
    for _, covered_base in ipairs(covered_bases) do
        local _, bottom_a, _, _ = util.get_text_area_dimensions(covered_base)
        local _, bottom_b, _, _ = util.get_text_area_dimensions(bottom_base)
        if bottom_a > bottom_b then
            bottom_base = covered_base
        end
    end
    vim.g.manually_switching_window_focus = true
    vim.fn.win_gotoid(bottom_base)
    vim.g.manually_switching_window_focus = false
    vim.cmd.wincmd('j')
    vim.cmd.doautocmd("User DetourWinEnter") -- This is necessary as the above wincmd is not guaranteed to trigger WinEnter (as any actual window movement may not occur)
end

function M.DetourWinCmdK()
    local covered_bases = util.find_covered_bases(vim.api.nvim_get_current_win())
    local top_base = covered_bases[1]
    for _, covered_base in ipairs(covered_bases) do
        local top_a, _, _, _ = util.get_text_area_dimensions(covered_base)
        local top_b, _, _, _ = util.get_text_area_dimensions(top_base)
        if top_a < top_b then
            top_base = covered_base
        end
    end
    vim.g.manually_switching_window_focus = true
    vim.fn.win_gotoid(top_base)
    vim.g.manually_switching_window_focus = false
    vim.cmd.wincmd('k')
    vim.cmd.doautocmd("User DetourWinEnter") -- This is necessary as the above wincmd is not guaranteed to trigger WinEnter (as any actual window movement may not occur)
end

function M.DetourWinCmdW()
    vim.g.manually_switching_window_focus = true
    vim.cmd.wincmd('w')
    vim.g.manually_switching_window_focus = false
    while vim.api.nvim_get_current_win() ~= util.find_top_popup() do
        -- TODO: add in a mechanism to prevent infinite loop
        vim.g.manually_switching_window_focus = true
        vim.cmd.wincmd('w')
        vim.g.manually_switching_window_focus = false
    end
end

return M
