local detour = require("detour")
local util = require("detour.util")
local features = require("detour.features")

describe("detour hide/reveal", function()
	before_each(function()
		vim.g.detour_testing = true
		vim.cmd([[
        %bwipeout!
        mapclear
        nmapclear
        vmapclear
        xmapclear
        smapclear
        omapclear
        mapclear
        imapclear
        lmapclear
        cmapclear
        tmapclear
        ]])
		vim.api.nvim_clear_autocmds({})
		for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ pattern = "*" })) do
			if vim.startswith(autocmd.group_name, "detour-") then
				vim.api.nvim_del_autocmd(autocmd.id)
			end
		end
		vim.o.splitbelow = true
		vim.o.splitright = true
	end)

	it("HideAllDetours and RevealAllDetours toggle popup visibility", function()
		-- Create two side-by-side base windows
		vim.cmd.vsplit()
		vim.cmd.wincmd("h")
		local left_base = vim.api.nvim_get_current_win()
		vim.cmd.wincmd("l")
		local right_base = vim.api.nvim_get_current_win()

		-- Create a detour over each base window
		vim.fn.win_gotoid(right_base)
		local right_popup = assert(detour.DetourCurrentWindow())
		vim.fn.win_gotoid(left_base)
		local left_popup = assert(detour.DetourCurrentWindow())

		-- Initially, popups are visible
		assert.False(vim.api.nvim_win_get_config(left_popup).hide or false)
		assert.False(vim.api.nvim_win_get_config(right_popup).hide or false)

		-- Hide all detours
		features.HideAllDetours()
		assert.True(vim.api.nvim_win_get_config(left_popup).hide)
		assert.True(vim.api.nvim_win_get_config(right_popup).hide)

		-- Reveal all detours
		features.RevealAllDetours()
		assert.False(vim.api.nvim_win_get_config(left_popup).hide)
		assert.False(vim.api.nvim_win_get_config(right_popup).hide)
	end)
end)
