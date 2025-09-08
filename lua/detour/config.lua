---@mod detour.config
---User configuration and defaults for detour.nvim.

---@class detour.config.Options
---@field title "none"|"path"

local config = {}

---@type detour.config.Options
local defaults = {
	title = "path",
}

---@type detour.config.Options
config.options = {}

---Setup detour.nvim configuration.
---@param args? detour.config.Options
config.setup = function(args)
	args = args or {}

	local new_options =
		vim.tbl_deep_extend("force", defaults, config.options, args or {})

	if not vim.tbl_contains({ "none", "path" }, new_options.title) then
		vim.api.nvim_echo({
			{
				'"'
					.. tostring(new_options.title)
					.. '" is an invalid value for title. Not changing detour configs.',
			},
		}, true, { err = true })
		return
	end

	config.options = new_options
end

config.setup()

return config
