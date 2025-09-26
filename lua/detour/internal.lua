-- DO NOT DEPEND ON THIS FILE!
-- This is an "internal" file and can have breaking changes without warning.

---@mod detour.internal
---Internal implementation details. Not part of the public API.

local internal = {}

---@class detour.internal
---@field construct_augroup_name fun(window_id: integer): string
---@field teardown_detour fun(window_id: integer)
---@field record_popup fun(popup_id: integer, coverable_windows: integer[]): boolean
---@field list_popups fun(): integer[]
---@field list_reserved_windows fun(): integer[]
---@field garbage_collect fun()
---@field is_detour fun(window: integer): boolean
---@field get_reserved_windows fun(popup_id: integer): integer[]|nil
---@field unreserve_window fun(window: integer): boolean

---@type table<integer, integer[]>
internal.popup_to_reserved_windows = {}

---@param window_id integer
---@return string
function internal.construct_augroup_name(window_id)
	return "detour-" .. window_id
end

-- Needs to be idempotent
---@param window_id integer
function internal.teardown_detour(window_id)
	-- Be tolerant if the augroup was already removed by another path.
	pcall(
		vim.api.nvim_del_augroup_by_name,
		internal.construct_augroup_name(window_id)
	)
	for _, covered_window in
		ipairs(internal.get_reserved_windows(window_id) or {})
	do
		if vim.api.nvim_win_get_config(covered_window).relative ~= "" then
			vim.api.nvim_win_set_config(
				covered_window,
				vim.tbl_extend(
					"force",
					vim.api.nvim_win_get_config(covered_window),
					{ focusable = true }
				)
			)
		end
	end
	internal.popup_to_reserved_windows[window_id] = nil
end

function internal.is_detour(window)
	return internal.popup_to_reserved_windows[window] ~= nil
end

---@param popup_id integer
---@return integer[]|nil
function internal.get_reserved_windows(popup_id)
	if internal.popup_to_reserved_windows[popup_id] == nil then
		return nil
	end

	-- Clean up any windows that have already been closed
	internal.popup_to_reserved_windows[popup_id] = vim.tbl_filter(
		function(window_id)
			return vim.tbl_contains(vim.api.nvim_list_wins(), window_id)
		end,
		internal.popup_to_reserved_windows[popup_id]
	)

	return internal.popup_to_reserved_windows[popup_id]
end

---@param popup_id integer
---@param coverable_windows integer[]
---@return boolean
function internal.record_popup(popup_id, coverable_windows)
	local open_windows = vim.api.nvim_list_wins()
	coverable_windows = vim.tbl_filter(function(window_id)
		return vim.tbl_contains(open_windows, window_id)
	end, coverable_windows)

	if #coverable_windows == 0 then
		vim.api.nvim_echo({
			{
				"[detour.nvim] You must provide at least one valid (open) coverable window.",
			},
		}, true, { err = true })
		return false
	end
	internal.popup_to_reserved_windows[popup_id] = coverable_windows
	return true
end

---@return integer[]
function internal.list_popups()
	return vim.tbl_keys(internal.popup_to_reserved_windows)
end

---@return integer[]
function internal.list_reserved_windows()
	local windows = vim.api.nvim_list_wins()
	return vim.iter(vim.tbl_values(internal.popup_to_reserved_windows))
		:flatten()
		:filter(function(w)
			return vim.tbl_contains(windows, w) -- make sure window is still open
		end)
		:totable()
end

---@param window integer
---@return boolean
function internal.unreserve_window(window)
	window = assert(tonumber(window))
	internal.garbage_collect()
	local copy = vim.tbl_extend("force", internal.popup_to_reserved_windows, {})
	for popup, reserved_windows in pairs(internal.popup_to_reserved_windows) do
		copy[popup] = vim.iter(reserved_windows)
			:filter(function(reserved)
				return tonumber(reserved) ~= tonumber(window)
			end)
			:totable()
		if #copy[popup] == 0 then
			-- A detour must have at least one window to float over,
			return false
		end
	end
	local changed = not vim.deep_equal(internal.popup_to_reserved_windows, copy)
	internal.popup_to_reserved_windows = copy
	return changed
end

-- Neovim autocmd events are quite nuanced:
-- 1. Autocmds do not trigger autocmd events by default (you need to set `nested
--    = true` to do that).
-- 2. WinClosed autocmds do not trigger WinClosed events even if `nested = true`.
-- 3. Even with `nested = true`, there is a limit to how many nested events
--    Neovim will trigger (max depth is 10).
-- Hence, there are possible cases where popup detours will be closed by the
-- user's autocmds without triggering a WinClosed event. To address this, we
-- must make sure to update the plugin's state before executing each user
-- command. Also, we must double check what windows are still open during this
-- plugin's autocmd callbacks.
function internal.garbage_collect()
	for _, popup_id in ipairs(internal.list_popups()) do
		if not vim.tbl_contains(vim.api.nvim_list_wins(), popup_id) then
			internal.teardown_detour(popup_id)
		end
	end
end

assert(
	vim.fn.timer_start(
		300,
		vim.schedule_wrap(internal.garbage_collect),
		{ ["repeat"] = -1 }
	) ~= -1,
	"[detour.nvim] Failed to create garbage_collect timer."
)

local group = vim.api.nvim_create_augroup("detour_internal", {})

local just_entered_window = false
vim.api.nvim_create_autocmd({ "WinEnter" }, {
	group = group,
	callback = function()
		just_entered_window = true
	end,
})

-- If the user interacts with a window, we should prevent detours from covering
-- it.
vim.api.nvim_create_autocmd({ "CursorMoved", "ModeChanged" }, {
	group = group,
	callback = function()
		-- Ignore this event if `WinEnter` just happened.
		if just_entered_window == true then
			just_entered_window = false
			return
		end

		if internal.unreserve_window(vim.api.nvim_get_current_win()) then
			vim.api.nvim_exec_autocmds("VimResized", {})
		end
	end,
})

-- Do not unreserve windows when WinScrolled is triggered by a WinResized.
vim.api.nvim_create_autocmd({ "WinResized" }, {
	group = group,
	callback = function(ev)
		for _, win in
			ipairs(
				vim.tbl_deep_extend(
					"force",
					vim.v.event.windows or {},
					ev.data.windows
				)
			)
		do
			vim.w[tonumber(win)].detour_just_resized_window = true
		end
	end,
})

-- Unreserves windows that got a new buffer or scrolled on the same buffer.
vim.api.nvim_create_autocmd({ "WinScrolled" }, {
	group = group,
	callback = function(ev)
		local unreserved = false
		for win in pairs(vim.tbl_deep_extend("force", vim.v.event, ev.data)) do
			win = tonumber(win)
			if win ~= nil then -- skip over "any" key
				if
					not vim.w[tonumber(win)]
					or not vim.w[win].detour_just_resized_window
				then
					unreserved = internal.unreserve_window(win) or unreserved
				end
			end
		end

		if unreserved then
			vim.api.nvim_exec_autocmds("VimResized", {})
		end
	end,
})

vim.api.nvim_create_autocmd({ "SafeState" }, {
	group = group,
	callback = function()
		just_entered_window = false
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			vim.w[win].detour_just_resized_window = false
		end
	end,
})

return internal
