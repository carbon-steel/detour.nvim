local detour = require("detour")
local config = require("detour.config")

describe("detour config", function()
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
		-- Reset to default configuration for each test
		config.setup({ title = "path" })
	end)

	it("disables titles when title = 'none'", function()
		config.setup({ title = "none" })
		assert(detour.Detour())
		-- With title disabled, floating window should not have a title
		assert.is_nil(vim.api.nvim_win_get_config(0).title)
	end)

	it("rejects invalid options and keeps previous config", function()
		local before = config.options.title
		config.setup({ title = "not-a-valid-option" })
		assert.same(before, config.options.title)
	end)
end)
