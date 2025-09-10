local detour = require("detour")
local internal = require("detour.internal")
local util = require("detour.util")

describe("detour internal", function()
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
		for _, autocmd in ipairs(vim.api.nvim_get_autocmds({})) do
			if vim.startswith(autocmd.group_name, "detour-") then
				vim.api.nvim_del_autocmd(autocmd.id)
			end
		end
		vim.o.splitbelow = true
		vim.o.splitright = true
	end)

	it("teardown is idempotent and clears reservations", function()
		local popup = assert(detour.Detour())
		internal.teardown_detour(popup)
		internal.teardown_detour(popup)
		assert.is_nil(internal.get_reserved_windows(popup))
	end)

	it("garbage_collect removes closed popups", function()
		local popup = assert(detour.Detour())
		vim.api.nvim_win_close(popup, true)
		internal.garbage_collect()
		assert.False(vim.tbl_contains(internal.list_popups(), popup))
		assert.is_nil(internal.get_reserved_windows(popup))
	end)

	it("get_reserved_windows filters out closed windows", function()
		vim.cmd.vsplit()
		local right = vim.api.nvim_get_current_win()

		local popup = assert(detour.Detour())
		assert.True(util.overlap(popup, right))

		-- Close one base and ensure it is removed from reservations
		vim.fn.win_gotoid(right)
		vim.api.nvim_win_close(right, true)
		local reserved = internal.get_reserved_windows(popup)
		assert.truthy(reserved)
		assert.False(vim.tbl_contains(reserved, right))
	end)
end)
