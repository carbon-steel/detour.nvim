-- Put this code in its own library to make sure it's only run once.

local util = require("detour.util")
local internal = require("detour.internal")

local ns = vim.api.nvim_create_namespace("detour.nvim-ns")

local timer = vim.loop.new_timer()

local function debounce(ms, fn)
	return function(...)
		local argv = { ... }
		timer:start(ms, 0, function()
			timer:stop()
			vim.schedule_wrap(fn)(unpack(argv))
		end)
	end
end

local function update_title(_, window_id)
	if vim.tbl_contains(internal.list_popups(), window_id) then
		vim.cmd.doautocmd("User DetourUpdateTitle" .. util.stringify(window_id))
	end
end

-- The reason why we're using a callback on decoration_provider instead of using an autocmd on BufEnter is because we
-- want to trigger a title update while browsing through netrw directories and that doesn't trigger BufEnter.
vim.api.nvim_set_decoration_provider(ns, {
	on_win = debounce(200, update_title),
})
return {}
