local detour = require("detour")
local util = require("detour.util")
local features = require("detour.features")

describe("features.CloseCurrentStack", function()
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

	it("closes a single detour and returns to base", function()
		local base = vim.api.nvim_get_current_win()
		local popup = assert(detour.Detour())

		features.CloseCurrentStack()

		assert.False(util.is_open(popup))
		assert.same({ base }, vim.api.nvim_list_wins())
	end)

	it("closes all nested detours in the chain", function()
		local original = vim.api.nvim_get_current_win()
		vim.cmd.split()
		local base = vim.api.nvim_get_current_win()
		local parent = assert(detour.Detour())
		local child = assert(detour.Detour())
		local grandchild = assert(detour.Detour())

		features.CloseCurrentStack()

		assert.False(util.is_open(parent))
		assert.False(util.is_open(child))
		assert.False(util.is_open(grandchild))
		assert.same({ original, base }, vim.api.nvim_list_wins())
		vim.api.nvim_win_close(base, true)
	end)

	it("is a no-op when not inside a detour", function()
		vim.cmd.split()
		local base = vim.api.nvim_get_current_win()
		local before = vim.api.nvim_list_wins()

		features.CloseCurrentStack()

		local after = vim.api.nvim_list_wins()
		assert.same(before, after)
		assert.same(base, vim.api.nvim_get_current_win())
		vim.cmd.close()
	end)
end)
