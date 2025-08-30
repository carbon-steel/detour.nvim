local M = {}

local util = require("detour.util")
local internal = require("detour.internal")
local algo = require("detour.windowing_algorithm")
local settings = require("detour.config")

-- This plugin utilizes custom User events:
-- * User DetourPopupResized<id>: This event is triggered whenever a detour
-- popup is resized. The event pattern has the window's ID concatenated to it.

---Construct nested float window opts within a parent float.
---@param parent integer
---@param layer integer?
---@return table
local function construct_nest(parent, layer)
	local top, bottom, left, right = util.get_text_area_dimensions(parent)
	local width = right - left
	local height = bottom - top
	local border = "rounded"
	if height >= 3 then
		height = height - 2
		top = top + 1
	end
	if width >= 3 then
		width = width - 2
		left = left + 1
	end
	return {
		relative = "editor",
		row = top,
		col = left,
		width = width,
		height = height,
		border = border,
		zindex = layer,
	}
end

---Resize an existing popup and update covered windows' focusability.
---@param window_id integer
---@param new_window_opts table?
local function resize_popup(window_id, new_window_opts)
	if new_window_opts == nil then
		return
	end

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
	local tab_id = vim.api.nvim_get_current_tabpage()

	if vim.tbl_contains(internal.list_coverable_windows(), parent) then
		vim.api.nvim_echo({
			{
				"[detour.nvim] This popup already has a child nested inside it: "
					.. parent,
			},
		}, true, { err = true })
		return nil
	end

	local parent_zindex = util.get_maybe_zindex(parent) or 0
	local window_opts = construct_nest(parent, parent_zindex + 1)

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
			local new_window_opts = construct_nest(parent)
			resize_popup(child, new_window_opts)
		end,
	})
	vim.api.nvim_create_autocmd({ "WinClosed" }, {
		group = augroup_id,
		pattern = "" .. child,
		callback = function()
			internal.teardown_detour(child)
			if
				vim.tbl_contains(vim.api.nvim_tabpage_list_wins(tab_id), parent)
			then
				vim.fn.win_gotoid(parent)
			end
		end,
		nested = true,
	})

	-- We're running this to make sure initializing popups runs the same code
	-- path as updating popups
	-- We make sure to do this after all state and autocmds are set.
	vim.api.nvim_exec_autocmds("User", {
		pattern = "DetourPopupResized" .. util.stringify(parent),
	})
	if settings.options.title == "path" then
		require("detour.features").ShowPathInTitle(child)
	end
	return child
end

---Create a base popup covering the given windows (or all non-floating windows).
---@param bufnr integer
---@param coverable_windows integer[]?
---@return integer|nil popup_id
local function popup(bufnr, coverable_windows)
	local tab_id = vim.api.nvim_get_current_tabpage()
	if coverable_windows == nil then
		coverable_windows = vim.tbl_filter(function(window)
			return not (
				util.is_floating(window)
				or vim.tbl_contains(internal.list_coverable_windows(), window)
			)
		end, vim.api.nvim_tabpage_list_wins(tab_id))
	end

	if #coverable_windows == 0 then
		vim.api.nvim_echo(
			{ { "[detour.nvim] No windows provided in coverable_windows." } },
			true,
			{ err = true }
		)
		return nil
	end

	for _, window in ipairs(coverable_windows) do
		if util.is_floating(window) then
			vim.api.nvim_echo({
				{
					"[detour.nvim] No floating windows allowed in base (ie, non-nested) popup "
						.. window,
				},
			}, true, { err = true })
			return nil
		end

		if vim.tbl_contains(internal.list_coverable_windows(), window) then
			vim.api.nvim_echo({
				{
					"[detour.nvim] This window is already reserved by another popup: "
						.. window,
				},
			}, true, { err = true })
			return nil
		end
	end

	-- We call handle_base_resize() later which overwrites the window_opts we set here, but this is still useful to validate that a popup can successfully be created at all.
	local window_opts = algo.construct_window_opts(coverable_windows, tab_id)
	if window_opts == nil then
		return nil
	end

	local popup_id = vim.api.nvim_open_win(bufnr, true, window_opts)
	if not internal.record_popup(popup_id, coverable_windows) then
		vim.api.nvim_win_close(popup_id, true)
		return nil
	end

	local augroup_id = vim.api.nvim_create_augroup(
		internal.construct_augroup_name(popup_id),
		{}
	)

	local function handle_base_resize()
		-- Even if construct_window_opts returns nil, do not close the popup as
		-- it is being used by the user. Just leave it for the user to handle.
		resize_popup(
			popup_id,
			algo.construct_window_opts(coverable_windows, tab_id)
		)
	end

	vim.api.nvim_create_autocmd({ "WinResized", "VimResized" }, {
		group = augroup_id,
		callback = function()
			if not util.is_open(popup_id) then
				internal.teardown_detour(popup_id)
				return
			end
			-- WinResized populates vim.v.event.windows but VimResized does not
			-- so we default to listing all windows.
			for _, x in
				ipairs(
					vim.v.event.windows
						or vim.api.nvim_tabpage_list_wins(tab_id)
				)
			do
				if
					vim.list_contains(vim.api.nvim_tabpage_list_wins(tab_id), x)
				then
					handle_base_resize()
					break
				end
			end
		end,
	})
	vim.api.nvim_create_autocmd({ "WinClosed" }, {
		group = augroup_id,
		pattern = "" .. popup_id,
		callback = function()
			internal.teardown_detour(popup_id)
			for _, base in ipairs(coverable_windows) do
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
		nested = true,
	})

	-- We're running this to make sure initializing popups runs the same code
	-- path as updating popups We make sure to do this after all state and
	-- autocmds are set.
	handle_base_resize()

	if settings.options.title == "path" then
		require("detour.features").ShowPathInTitle(popup_id)
	end

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
