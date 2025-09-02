local detour = require("detour")
local movements = require("detour.movements")
local util = require("detour.util")

function Set(list)
	local set = {}
	for _, l in ipairs(list) do
		set[l] = true
	end
	return set
end

describe("detour", function()
	before_each(function()
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
		vim.api.nvim_clear_autocmds({}) -- delete any autocmds not in a group
		for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ pattern = "*" })) do
			if vim.startswith(autocmd.group_name, "detour-") then
				vim.api.nvim_del_autocmd(autocmd.id)
			end
		end
		vim.o.splitbelow = true
		vim.o.splitright = true
	end)

	it("Switching horizontally between detours", function()
		local left_base = vim.api.nvim_get_current_win()

		vim.cmd.vsplit()
		local middle_base = vim.api.nvim_get_current_win()

		vim.cmd.vsplit()
		local right_base = vim.api.nvim_get_current_win()

		vim.fn.win_gotoid(middle_base)
		local middle_popup = assert(detour.DetourCurrentWindow())

		-- Enter and leave a popup from a base window in both directions
		movements.DetourWinCmdH()
		assert.same(vim.api.nvim_get_current_win(), left_base)

		movements.DetourWinCmdL()
		assert.same(vim.api.nvim_get_current_win(), middle_popup)

		movements.DetourWinCmdL()
		assert.same(vim.api.nvim_get_current_win(), right_base)

		movements.DetourWinCmdH()
		assert.same(vim.api.nvim_get_current_win(), middle_popup)

		-- Create nested popup
		local middle_nested_popup = assert(detour.DetourCurrentWindow())

		-- Enter and leave a nested popup from a base window in both directions
		movements.DetourWinCmdH()
		assert.same(vim.api.nvim_get_current_win(), left_base)

		movements.DetourWinCmdL()
		assert.same(vim.api.nvim_get_current_win(), middle_nested_popup)

		movements.DetourWinCmdL()
		assert.same(vim.api.nvim_get_current_win(), right_base)

		movements.DetourWinCmdH()
		assert.same(vim.api.nvim_get_current_win(), middle_nested_popup)

		-- Create popups on left and right
		vim.fn.win_gotoid(left_base)
		local left_popup = assert(detour.DetourCurrentWindow())

		vim.fn.win_gotoid(right_base)
		local right_popup = assert(detour.DetourCurrentWindow())

		vim.fn.win_gotoid(middle_nested_popup)

		-- Enter and leave a nested popup from a non-nested popup in both directions
		movements.DetourWinCmdH()
		assert.same(vim.api.nvim_get_current_win(), left_popup)

		movements.DetourWinCmdL()
		assert.same(vim.api.nvim_get_current_win(), middle_nested_popup)

		movements.DetourWinCmdL()
		assert.same(vim.api.nvim_get_current_win(), right_popup)

		movements.DetourWinCmdH()
		assert.same(vim.api.nvim_get_current_win(), middle_nested_popup)
	end)

	it("Switching vertically between detours", function()
		local top_base = vim.api.nvim_get_current_win()

		vim.cmd.split()
		local middle_base = vim.api.nvim_get_current_win()

		vim.cmd.split()
		local bottom_base = vim.api.nvim_get_current_win()

		vim.fn.win_gotoid(middle_base)
		local middle_popup = assert(detour.DetourCurrentWindow())

		-- Enter and leave a popup from a base window in both directions
		movements.DetourWinCmdK()
		assert.same(vim.api.nvim_get_current_win(), top_base)

		movements.DetourWinCmdJ()
		assert.same(vim.api.nvim_get_current_win(), middle_popup)

		movements.DetourWinCmdJ()
		assert.same(vim.api.nvim_get_current_win(), bottom_base)

		movements.DetourWinCmdK()
		assert.same(vim.api.nvim_get_current_win(), middle_popup)

		-- Create nested popup
		local middle_nested_popup = assert(detour.DetourCurrentWindow())

		-- Enter and leave a nested popup from a base window in both directions
		movements.DetourWinCmdK()
		assert.same(vim.api.nvim_get_current_win(), top_base)

		movements.DetourWinCmdJ()
		assert.same(vim.api.nvim_get_current_win(), middle_nested_popup)

		movements.DetourWinCmdJ()
		assert.same(vim.api.nvim_get_current_win(), bottom_base)

		movements.DetourWinCmdK()
		assert.same(vim.api.nvim_get_current_win(), middle_nested_popup)

		-- Create popups on top and bottom
		vim.fn.win_gotoid(top_base)
		local top_popup = assert(detour.DetourCurrentWindow())

		vim.fn.win_gotoid(bottom_base)
		local bottom_popup = assert(detour.DetourCurrentWindow())

		vim.fn.win_gotoid(middle_nested_popup)

		-- Enter and leave a nested popup from a non-nested popup in both directions
		movements.DetourWinCmdK()
		assert.same(vim.api.nvim_get_current_win(), top_popup)

		movements.DetourWinCmdJ()
		assert.same(vim.api.nvim_get_current_win(), middle_nested_popup)

		movements.DetourWinCmdJ()
		assert.same(vim.api.nvim_get_current_win(), bottom_popup)

		movements.DetourWinCmdK()
		assert.same(vim.api.nvim_get_current_win(), middle_nested_popup)
	end)

	it("Switch windows with <C-w>w", function()
		local base = vim.api.nvim_get_current_win()
		local popup = detour.Detour()

		vim.cmd.split()
		local bottom_base = vim.api.nvim_get_current_win()
		assert.is_not.same(bottom_base, popup)

		movements.DetourWinCmdW()

		assert.same(popup, vim.api.nvim_get_current_win())

		movements.DetourWinCmdW()
		assert.same(bottom_base, vim.api.nvim_get_current_win())
	end)

	it("Move cursor on SafeState", function()
		local base = vim.api.nvim_get_current_win()
		local popup = detour.Detour()

		vim.opt.eventignore = "all" -- deactivate plugin
		vim.api.nvim_set_current_win(base)
		vim.opt.eventignore = "" -- reactivate plugin
		movements._safe_state_handler()
		assert.same(popup, vim.api.nvim_get_current_win())
	end)
end)
