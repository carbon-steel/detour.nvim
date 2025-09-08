---@mod detour.show_path_in_title
---Internal helper for updating popup titles.

-- Put this code in its own library to make sure it's only run once.

local util = require("detour.util")
local internal = require("detour.internal")

---@type integer
local ns = vim.api.nvim_create_namespace("detour.nvim-ns")

---@type uv.uv_timer_t
local timer = assert(vim.uv.new_timer())

-- This implements a trailing debouce where each call to the debounced function
-- will start a timer and cancel any existing timers for that function. The
-- function will eventually be called with the arguments from its most recent
-- call.
---@param ms integer
---@param fn fun(...: any)
---@return fun(...: any)
local function debounce(ms, fn)
	return function(...)
		local argv = { ... }
		timer:stop()
		timer:start(ms, 0, function()
			vim.schedule_wrap(fn)(unpack(argv))
		end)
	end
end

---@param _ any
---@param window_id integer
local function update_title(_, window_id)
    if vim.tbl_contains(internal.list_popups(), window_id) then
        vim.api.nvim_exec_autocmds("User", {
            pattern = "DetourUpdateTitle" .. util.stringify(window_id),
        })
    end
end

-- The reason why we're using a callback on decoration_provider instead of using an autocmd on BufEnter is because we
-- want to trigger a title update while browsing through netrw directories and that doesn't trigger BufEnter.
--
-- From `api.txt`:
-- (About nvim_set_decoration_provider) doing anything other than setting
-- extmarks is considered experimental. Doing things like changing options are
-- not explicitly forbidden, but is likely to have unexpected consequences (such
-- as 100% CPU consumption). Doing `vim.rpcnotify` should be OK, but
-- `vim.rpcrequest` is quite dubious for the moment.
--
-- I debounce `update_title` since rapidly changing the title with `on_win`
-- causes neovim to freeze.
vim.api.nvim_set_decoration_provider(ns, {
	on_win = debounce(50, update_title),
})
return {}
