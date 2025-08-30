local M = {}

local defaults = {
	title = "path",
}

M.options = {}

M.setup = function(args)
	args = args or {}

	local new_options = vim.tbl_deep_extend("force", defaults, args or {})

	if not vim.tbl_contains({ "none", "path" }, new_options.title) then
		vim.api.nvim_err_writeln(
			'"'
				.. tostring(new_options.title)
				.. '" is an invalid value for title. Not changing detour configs.'
		)
		return
	end

	M.options = new_options
end

M.setup()

return M
