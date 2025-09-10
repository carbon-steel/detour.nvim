local util = require("detour.util")

describe("detour util", function()
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
		for _, autocmd in ipairs(vim.api.nvim_get_autocmds({})) do
			if vim.startswith(autocmd.group_name, "detour-") then
				vim.api.nvim_del_autocmd(autocmd.id)
			end
		end
		vim.o.splitbelow = true
		vim.o.splitright = true
	end)

	it("pairs_by_keys iterates keys in order", function()
		local t = { c = 3, a = 1, b = 2 }
		local keys = {}
		for k in util.pairs_by_keys(t) do
			table.insert(keys, k)
		end
		assert.same({ "a", "b", "c" }, keys)
	end)

	it("stringify maps digits to letters", function()
		assert.same("bc", util.stringify(12))
		assert.same("bcd", util.stringify(123))
	end)

	it("base_at_screenpos finds base window by coordinates", function()
		local tab = vim.api.nvim_get_current_tabpage()
		-- two columns layout
		local left = vim.api.nvim_get_current_win()
		vim.cmd.vsplit()
		local right = vim.api.nvim_get_current_win()

		local function inside(win)
			local top, _, leftx, _ = util.get_text_area_dimensions(win)
			return top + 1, leftx + 1
		end

		local r, c = inside(left)
		assert.same(left, util.base_at_screenpos(tab, r, c))

		r, c = inside(right)
		assert.same(right, util.base_at_screenpos(tab, r, c))
	end)
end)
