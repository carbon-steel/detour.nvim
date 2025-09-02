local detour = require("detour")
local util = require("detour.util")

local function Set(list)
	local set = {}
	for _, l in ipairs(list) do
		set[l] = true
	end
	return set
end

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
end)
