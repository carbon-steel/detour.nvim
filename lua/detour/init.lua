local M = {}

local util = require("detour.util")
local internal = require("detour.internal")
local algo = require("detour.windowing_algorithm")
local settings = require("detour.config")

-- This plugin utilizes custom User events:
-- * User DetourPopupResized<id>: This event is triggered whenever a detour
-- popup is resized. The event pattern has the window's ID concatenated to it.

---Resize an existing popup and update covered windows' focusability.
---@param window_id integer
---@param new_window_opts table
local function resize_popup(window_id, new_window_opts)
	local current_window_opts = vim.api.nvim_win_get_config(window_id)
	vim.api.nvim_win_set_config(
		window_id,
		vim.tbl_extend("force", current_window_opts, new_window_opts)
	)

	-- Not sure why this loop is necessary.
	for _, covered_window in
		ipairs(internal.get_coverable_windows(window_id) or {})
	do
		if util.is_floating(covered_window) then
			vim.api.nvim_win_set_config(
				covered_window,
				vim.tbl_extend(
					"force",
					vim.api.nvim_win_get_config(covered_window),
					{ focusable = not util.overlap(covered_window, window_id) }
				)
			)
		end
	end

	-- Sometimes, resizing terminal buffers can end up scrolling the terminal UI
	-- horizontally so that you only see a portion of the terminal UI. This code
	-- scrolls the terminal UI so that the window keeps showing the leftmost
	-- column
	--
	-- Condition on terminal mode (instead of checking whether buffer is
	-- terminal-type) just in case user was intentionally looking at a specific
	-- location in visual or normal mode.
	if vim.fn.mode() == "t" then
		local row = vim.api.nvim_win_get_position(window_id)[1]
		vim.api.nvim_win_set_cursor(window_id, { row, 0 })
	end

	-- Fully complete resizing before propogating event.
	vim.api.nvim_exec_autocmds("User", {
		pattern = "DetourPopupResized" .. util.stringify(window_id),
	})
end

---Create a nested popup above the current floating window.
---@return integer|nil popup_id
local function popup_above_float()
	local parent = vim.api.nvim_get_current_win()

	if vim.tbl_contains(internal.list_reserved_windows(), parent) then
		vim.api.nvim_echo({
			{
				"[detour.nvim] This popup already has a child nested inside it: "
					.. parent,
			},
		}, true, { err = true })
		return nil
	end

	local parent_zindex = util.get_maybe_zindex(parent) or 0
	local window_opts = algo.construct_nest(parent, parent_zindex + 1)

	local child =
		vim.api.nvim_open_win(vim.api.nvim_win_get_buf(0), true, window_opts)
	if not internal.record_popup(child, { parent }) then
		vim.api.nvim_win_close(child, true)
		return nil
	end

	local augroup_id =
		vim.api.nvim_create_augroup(internal.construct_augroup_name(child), {})
	vim.api.nvim_create_autocmd({ "User" }, {
		pattern = "DetourPopupResized" .. util.stringify(parent),
		group = augroup_id,
		callback = function()
			if not util.is_open(child) then
				internal.teardown_detour(child)
				return
			end

			if util.is_open(parent) then
				resize_popup(child, algo.construct_nest(parent))
			end
		end,
	})
	vim.api.nvim_create_autocmd({ "WinClosed" }, {
		group = augroup_id,
		pattern = tostring(child),
		callback = function()
			internal.teardown_detour(child)
			if util.is_open(parent) then
				vim.fn.win_gotoid(parent)
			end
		end,
		nested = true, -- Trigger all the autocmds for entering a new window
	})

	if settings.options.title == "path" then
		require("detour.features").ShowPathInTitle(child)
	end

	-- We're running this to make sure initializing popups runs the same code
	-- path as updating popups
	-- We make sure to do this after all state and autocmds are set.
	vim.api.nvim_exec_autocmds("User", {
		pattern = "DetourPopupResized" .. util.stringify(parent),
	})
	return child
end

---Create a base popup covering the given windows (or all non-floating windows).
---@param bufnr integer
---@param reserve_windows integer[]?
---@return integer|nil popup_id
local function popup(bufnr, reserve_windows)
	local tab_id = vim.api.nvim_get_current_tabpage()
	reserve_windows = reserve_windows
		or vim.tbl_filter(function(window)
			return not (
				util.is_floating(window)
				or vim.tbl_contains(internal.list_reserved_windows(), window)
			)
		end, vim.api.nvim_tabpage_list_wins(tab_id))

	if #reserve_windows == 0 then
		vim.api.nvim_echo(
			{ { "[detour.nvim] No windows provided in coverable_windows." } },
			true,
			{ err = true }
		)
		return nil
	end

	for _, window in ipairs(reserve_windows) do
		if util.is_floating(window) then
			vim.api.nvim_echo({
				{
					"[detour.nvim] No floating windows allowed in base (ie, non-nested) popup "
						.. window,
				},
			}, true, { err = true })
			return nil
		end

		if vim.tbl_contains(internal.list_reserved_windows(), window) then
			vim.api.nvim_echo({
				{
					"[detour.nvim] This window is already reserved by another detour: "
						.. window,
				},
			}, true, { err = true })
			return nil
		end
	end

	local window_opts = algo.construct_window_opts(reserve_windows, tab_id)
	if window_opts == nil then
		return nil
	end

	local popup_id = vim.api.nvim_open_win(bufnr, true, window_opts)
	if not internal.record_popup(popup_id, reserve_windows) then
		vim.api.nvim_win_close(popup_id, true)
		return nil
	end

	local augroup_id = vim.api.nvim_create_augroup(
		internal.construct_augroup_name(popup_id),
		{}
	)

	vim.api.nvim_create_autocmd({ "WinResized" }, {
		group = augroup_id,
		callback = function()
			local reserved = internal.get_coverable_windows(popup_id)
			if reserved == nil then
				internal.teardown_detour(popup_id)
				return
			end
			-- WinResized populates vim.v.event.windows but VimResized does not
			-- so we default to listing all windows.
			local changed_window = assert(
				vim.v["event"]["windows"][1],
				"no windows listed in WinResized event"
			)
			local changed_tab = vim.api.nvim_win_get_tabpage(changed_window)
			if tab_id == changed_tab then
				local new_window_opts =
					algo.construct_window_opts(reserved, tab_id)
				if new_window_opts then
					resize_popup(popup_id, new_window_opts)
				end
			end
		end,
	})

	vim.api.nvim_create_autocmd({ "VimResized" }, {
		group = augroup_id,
		callback = function()
			local reserved = internal.get_coverable_windows(popup_id)
			if reserved == nil then
				internal.teardown_detour(popup_id)
				return
			end

			local new_window_opts = algo.construct_window_opts(reserved, tab_id)
			-- If there is an issue that prevents a valid configuration for the
			-- detour, just leave it for the user to manually clean up.
			if new_window_opts then
				resize_popup(popup_id, new_window_opts)
			end
		end,
	})

	vim.api.nvim_create_autocmd({ "WinClosed" }, {
		group = augroup_id,
		pattern = "" .. popup_id,
		callback = function()
			local reserved = internal.get_coverable_windows(popup_id)
			internal.teardown_detour(popup_id)
			for _, base in ipairs(reserved) do
				if
					vim.tbl_contains(
						vim.api.nvim_tabpage_list_wins(tab_id),
						base
					)
				then
					vim.fn.win_gotoid(base)
					return
				end
			end
		end,
		nested = true, -- Trigger all the autocmds for entering a new window
	})

	if settings.options.title == "path" then
		require("detour.features").ShowPathInTitle(popup_id)
	end

	-- We're running this to make sure initializing popups runs the same code
	-- path as updating popups. We make sure to do this after all state and
	-- autocmds are set.
	vim.api.nvim_exec_autocmds("VimResized", {})

	return popup_id
end

---Open a detour popup
---@return integer|nil popup_id
M.Detour = function()
	internal.garbage_collect()
	if util.is_floating(vim.api.nvim_get_current_win()) then
		return popup_above_float()
	end

	return popup(vim.api.nvim_get_current_buf())
end

---Open a detour popup covering only the current window.
---@return integer|nil popup_id
M.DetourCurrentWindow = function()
	internal.garbage_collect()

	if util.is_floating(vim.api.nvim_get_current_win()) then
		return popup_above_float()
	end

	return popup(
		vim.api.nvim_get_current_buf(),
		{ vim.api.nvim_get_current_win() }
	)
end

---@type fun(args?: detour.config.Options)
M.setup = require("detour.config").setup

return M
