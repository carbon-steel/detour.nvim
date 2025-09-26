local detour = require("detour")
local internal = require("detour.internal")
local util = require("detour.util")

describe("detour auto-unreserve on interaction", function()
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
		vim.api.nvim_clear_autocmds({}) -- delete any autocmds not in a group
		for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ pattern = "*" })) do
			if vim.startswith(autocmd.group_name, "detour-") then
				vim.api.nvim_del_autocmd(autocmd.id)
			end
		end
		vim.o.splitbelow = true
		vim.o.splitright = true
	end)

	it("unreserves interacted window and resizes popup", function()
		-- Create a 2-column layout
		local left_base = vim.api.nvim_get_current_win()
		vim.cmd.vsplit()
		local right_base = vim.api.nvim_get_current_win()

		-- Create a detour covering both base windows
		local popup = assert(detour.Detour())
		assert.True(util.overlap(popup, right_base))

		-- Focus the left base window, then simulate user interaction
		vim.cmd.split()
		vim.api.nvim_exec_autocmds("VimResized", {}) -- trigger detour resize
		assert.False(util.overlap(popup, right_base))
		vim.fn.win_gotoid(right_base)
		vim.cmd.startinsert() -- right_base should now be unreserved

		assert.are.same(util.find_covered_windows(popup), { left_base })
	end)

	it("unreserves windows that scroll", function()
		local left_base = vim.api.nvim_get_current_win()
		vim.cmd.vsplit()
		local right_base = vim.api.nvim_get_current_win()

		local popup = assert(detour.Detour())

		vim.api.nvim_exec_autocmds("WinScrolled", {
			data = {
				[tostring(right_base)] = {
					topline = 1,
					botline = 1,
					leftcol = 0,
					skipcol = 0,
				},
				all = { topline = 1, botline = 1, leftcol = 0, skipcol = 0 },
			},
		})

		assert.are.same(util.find_covered_windows(popup), { left_base })
	end)

	it("ignores WinScrolled triggered by WinResized", function()
		local left_base = vim.api.nvim_get_current_win()
		vim.cmd.vsplit()
		local right_base = vim.api.nvim_get_current_win()

		local popup = assert(detour.Detour())

		vim.api.nvim_exec_autocmds(
			"WinResized",
			{ data = { windows = { right_base } } }
		)

		vim.api.nvim_exec_autocmds("WinScrolled", {
			data = {
				[tostring(right_base)] = {
					topline = 1,
					botline = 1,
					leftcol = 0,
					skipcol = 0,
				},
				all = { topline = 1, botline = 1, leftcol = 0, skipcol = 0 },
			},
		})

		assert.are.same(
			util.find_covered_bases(popup),
			{ left_base, right_base }
		)
	end)

	it("resets resize flag on SafeState allowing future unreserves", function()
		local left_base = vim.api.nvim_get_current_win()
		vim.cmd.vsplit()
		local right_base = vim.api.nvim_get_current_win()

		local popup = assert(detour.Detour())

		vim.api.nvim_exec_autocmds(
			"WinResized",
			{ data = { windows = { right_base } } }
		)

		vim.api.nvim_exec_autocmds("SafeState", {})

		vim.api.nvim_exec_autocmds("WinScrolled", {
			data = {
				[tostring(right_base)] = {
					topline = 1,
					botline = 1,
					leftcol = 0,
					skipcol = 0,
				},
				all = { topline = 1, botline = 1, leftcol = 0, skipcol = 0 },
			},
		})

		assert.are.same(util.find_covered_bases(popup), { left_base })
	end)
end)
