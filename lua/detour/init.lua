local M = {}

local util = require("detour.util")
local internal = require("detour.internal")
local algo = require("detour.windowing_algorithm")
local settings = require("detour.config").options

-- This plugin utilizes custom User events:
-- * User DetourPopupResized<id>: This event is triggered whenever a detour popup is resized. The event pattern has the
-- window's ID concatenated to it.

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

-- Needs to be idempotent
local function teardownDetour(window_id)
	vim.api.nvim_del_augroup_by_name(util.construct_augroup_name(window_id))
	for _, covered_window in
		ipairs(internal.get_coverable_windows(window_id) or {})
	do
		if util.is_floating(covered_window) then
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
	internal.erase_popup(window_id)
end

local function resize_popup(window_id, new_window_opts)
	if new_window_opts == nil then
		return
	end

	local current_window_opts = vim.api.nvim_win_get_config(window_id)
	vim.api.nvim_win_set_config(
		window_id,
		vim.tbl_extend("force", current_window_opts, new_window_opts)
	)

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
	-- scrolls the terminal UI so that
	--
	-- Condition on terminal mode (instead of checking whether buffer is
	-- terminal-type) just in case user was intentionally looking at a specific
	-- location in visual or normal mode.
	if vim.fn.mode() == "t" then
		local row, _ = unpack(vim.api.nvim_win_get_position(window_id))
		vim.api.nvim_win_set_cursor(window_id, { row, 0 })
	end

	-- Fully complete resizing before propogating event.
	vim.cmd.doautocmd("User DetourPopupResized" .. util.stringify(window_id))
end

local function popup_above_float()
	local parent = vim.api.nvim_get_current_win()
	local tab_id = vim.api.nvim_get_current_tabpage()

	if vim.tbl_contains(internal.list_coverable_windows(), parent) then
		vim.api.nvim_err_writeln(
			"[detour.nvim] This popup already has a child nested inside it:"
				.. parent
		)
		return nil
	end

	local parent_zindex = util.get_maybe_zindex(parent) or 0
	local window_opts = construct_nest(parent, parent_zindex + 1)

	local child =
		vim.api.nvim_open_win(vim.api.nvim_win_get_buf(0), true, window_opts)
	internal.record_popup(child, { parent })
	local augroup_id =
		vim.api.nvim_create_augroup(util.construct_augroup_name(child), {})
	vim.api.nvim_create_autocmd({ "User" }, {
		pattern = "DetourPopupResized" .. util.stringify(parent),
		group = augroup_id,
		callback = function()
			if not util.is_open(child) then
				teardownDetour(child)
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
			teardownDetour(child)
			if
				vim.tbl_contains(vim.api.nvim_tabpage_list_wins(tab_id), parent)
			then
				vim.fn.win_gotoid(parent)
			end
		end,
	})

	vim.api.nvim_create_autocmd({ "WinClosed" }, {
		group = augroup_id,
		pattern = "" .. parent,
		callback = function()
			if not util.is_open(child) then
				teardownDetour(child)
				return
			end
			vim.api.nvim_win_close(child, false)
			-- Even if `nested` is set to true, WinClosed does not trigger itself.
			vim.cmd.doautocmd("WinClosed " .. child)
		end,
	})
	-- We're running this to make sure initializing popups runs the same code path as updating popups
	-- We make sure to do this after all state and autocmds are set.
	vim.cmd.doautocmd("User DetourPopupResized" .. util.stringify(parent))
	if settings.title == "path" then
		require("detour.features").ShowPathInTitle(child)
	end
	return child
end

local function popup(bufnr, coverable_windows)
	if util.is_floating(vim.api.nvim_get_current_win()) then
		return popup_above_float()
	end
	local tab_id = vim.api.nvim_get_current_tabpage()
	if coverable_windows == nil then
		coverable_windows = {}
		for _, window in ipairs(vim.api.nvim_tabpage_list_wins(tab_id)) do
			if
				not util.is_floating(window)
				and not vim.tbl_contains(
					internal.list_coverable_windows(),
					window
				)
			then
				table.insert(coverable_windows, window)
			end
		end
	end

	if #coverable_windows == 0 then
		vim.api.nvim_err_writeln(
			"[detour.nvim] No windows provided in coverable_windows."
		)
		return nil
	end

	for _, window in ipairs(coverable_windows) do
		if util.is_floating(window) then
			vim.api.nvim_err_writeln(
				"[detour.nvim] No floating windows allowed in base (ie, non-nested) popup"
					.. window
			)
			return nil
		end

		if vim.tbl_contains(internal.list_coverable_windows(), window) then
			vim.api.nvim_err_writeln(
				"[detour.nvim] This window is already reserved by another popup:"
					.. window
			)
			return nil
		end
	end

	-- We call handle_base_resize() later which overwrites the window_opts we set here, but this is still useful to validate that a popup can successfully be created at all.
	local window_opts = algo.construct_window_opts(coverable_windows, tab_id)
	if window_opts == nil then
		return nil
	end
	local popup_id = vim.api.nvim_open_win(bufnr, true, window_opts)
	internal.record_popup(popup_id, coverable_windows)
	local augroup_id =
		vim.api.nvim_create_augroup(util.construct_augroup_name(popup_id), {})

	local function handle_base_resize()
		if not util.is_open(popup_id) then
			teardownDetour(popup_id)
			return
		end
		local new_window_opts =
			algo.construct_window_opts(coverable_windows, tab_id)
		-- Even if new_window_opts is nil, do not close the popup as it is being used by the user. Just leave it for the user to handle.
		resize_popup(popup_id, new_window_opts)
	end

	vim.api.nvim_create_autocmd({ "WinResized", "VimResized" }, {
		group = augroup_id,
		callback = function()
			if not util.is_open(popup_id) then
				teardownDetour(popup_id)
				return
			end
			-- WinResized populates vim.v.event.windows but VimResized does not so we default to listing all windows.
			for _, x in
				ipairs(
					vim.v.event.windows
						or vim.api.nvim_tabpage_list_wins(tab_id)
				)
			do
				if
					util.contains_element(
						vim.api.nvim_tabpage_list_wins(tab_id),
						x
					)
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
			teardownDetour(popup_id)
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
	})

	for _, triggering_window in ipairs(coverable_windows) do
		vim.api.nvim_create_autocmd({ "WinClosed" }, {
			group = augroup_id,
			pattern = "" .. triggering_window,
			callback = function()
				if not util.is_open(popup_id) then
					teardownDetour(popup_id)
					return
				end
				local all_closed = true
				local open_windows = vim.api.nvim_tabpage_list_wins(tab_id)
				for _, covered_window in ipairs(coverable_windows) do
					if
						util.contains_element(open_windows, covered_window)
						and covered_window ~= triggering_window
					then
						all_closed = false
					end
				end

				if all_closed then
					vim.api.nvim_win_close(popup_id, false)
					-- Even if `nested` is set to true, WinClosed does not trigger itself.
					vim.cmd.doautocmd("WinClosed " .. popup_id)
				end
			end,
		})
	end
	-- We're running this to make sure initializing popups runs the same code path as updating popups
	-- We make sure to do this after all state and autocmds are set.
	handle_base_resize()

	if settings.title == "path" then
		require("detour.features").ShowPathInTitle(popup_id)
	end

	return popup_id
end

-- Neovim autocmd events are quite nuanced:
-- 1. Autocmds do not trigger autocmd events by default (you need to set `nested = true` to do that).
-- 2. WinClosed autocmds do not trigger WinClosed events even if `nested = true`.
-- 3. Even with `nested = true`, there is a limit to how many nested events Neovim will trigger (max depth is 10).
-- Hence, there are possible cases where popup detours will be closed by the user's autocmds without triggering a
-- WinClosed event. To address this, we must make sure to update the plugin's state before executing each user command.
-- Also, we must double check what windows are still open during this plugin's autocmd callbacks.
local function garbageCollect()
	for _, popup_id in ipairs(internal.list_popups()) do
		if not util.is_open(popup_id) then
			teardownDetour(popup_id)
		end
	end
end

assert(
	vim.fn.timer_start(
		300,
		vim.schedule_wrap(garbageCollect),
		{ ["repeat"] = -1 }
	) ~= -1,
	"[detour.nvim] Failed to create garbageCollect timer."
)

M.Detour = function()
	garbageCollect()
	return popup(vim.api.nvim_get_current_buf())
end

M.DetourCurrentWindow = function()
	garbageCollect()
	return popup(
		vim.api.nvim_get_current_buf(),
		{ vim.api.nvim_get_current_win() }
	)
end

M.setup = require("detour.config").setup

return M
