---@mod detour.features
---@brief [[
--- Optional detour.nvim features.
---
--- Utilities to enhance behavior of detour popups (titles, auto-close,
--- temporary hiding/revealing, uncovering with mouse, etc.).
---@brief ]]
---@tag detour.features

---@class detour.features
---@field ShowPathInTitle fun(popup_id: integer)
---@field CloseOnLeave fun(popup_id: integer)
---@field UncoverWindow fun(window: integer): boolean
---@field HideAllDetours fun()
---@field RevealAllDetours fun()
---@field UncoverWindowWithMouse fun()
---@field CloseCurrentStack fun(): boolean
local features = {}

local util = require("detour.util")
local internal = require("detour.internal")

---Update the detour window title to the current buffer path relative to cwd.
---@param window_id integer
local function update_title(window_id)
	local tabwin = vim.fn.win_id2tabwin(window_id)
	local tabnr, winnr = unpack(tabwin)
	if tabnr == 0 and winnr == 0 then
		return
	end
	local buffer_id = vim.api.nvim_win_get_buf(window_id)
	local path = vim.api.nvim_buf_get_name(buffer_id)
	local home = vim.fn.getcwd(winnr, tabnr)
	local title = vim.fn.fnamemodify(path, ":.")
	if title:sub(1, #home) == home then
		title = title:sub(#home + 1)
	end
	vim.api.nvim_win_set_config(
		window_id,
		vim.tbl_extend(
			"force",
			vim.api.nvim_win_get_config(window_id),
			{ title = title }
		)
	)
end

---Show the buffer path in the given popup's title and keep it updated.
---@param popup_id integer
function features.ShowPathInTitle(popup_id)
	require("detour.show_path_in_title")

	if
		next(vim.api.nvim_get_autocmds({
			pattern = "DetourUpdateTitle" .. util.stringify(popup_id),
			group = internal.construct_augroup_name(popup_id),
		})) ~= nil
	then
		-- ShowPathInTitle already called for this popup.
		return
	end

	update_title(popup_id)

	vim.api.nvim_create_autocmd({ "User" }, {
		pattern = "DetourUpdateTitle" .. util.stringify(popup_id),
		group = internal.construct_augroup_name(popup_id),
		callback = function()
			if not util.is_open(popup_id) then
				return true
			end
			update_title(popup_id)
		end,
	})
end

---Close the popup when focus leaves to a non-floating window.
---@param popup_id integer
function features.CloseOnLeave(popup_id)
	-- This autocmd will close the created detour popup when you focus on a different window.
	vim.api.nvim_create_autocmd({ "WinEnter" }, {
		group = internal.construct_augroup_name(popup_id),
		callback = function()
			local curr_window = vim.api.nvim_get_current_win()
			-- Skip cases where we are entering popups (eg, menus, nested popups, the detour popup itself).
			if vim.api.nvim_win_get_config(curr_window).relative ~= "" then
				return
			end

			-- Check to make sure the popup has not already been closed
			if util.is_open(popup_id) then
				vim.api.nvim_win_close(popup_id, false)
			end
		end,
		nested = true,
	})
end

---Prevent detours from covering the provided window.
---@param window integer
---@return boolean
function features.UncoverWindow(window)
	local ok = internal.unreserve_window(window)
	if ok then
		vim.api.nvim_exec_autocmds("VimResized", {})
	end
	return ok
end

---Temporarily hide all detours in current tabpage.
---@return nil
function features.HideAllDetours()
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if internal.is_detour(win) then
			vim.api.nvim_win_set_config(win, { hide = true })
		end
	end
	vim.cmd("redraw!")
end

---Reveal all detours previously hidden in current tabpage.
---@return nil
function features.RevealAllDetours()
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if internal.is_detour(win) then
			vim.api.nvim_win_set_config(win, { hide = false })
		end
	end
	vim.cmd("redraw!")
end

---Prompt to click a window and mark it as uncovered by detours.
---@return nil
function features.UncoverWindowWithMouse()
	local prev_mouse = vim.o.mouse
	if not prev_mouse:match("a") then
		vim.o.mouse = "a"
	end
	vim.api.nvim_echo(
		{ { "Click a window (Press any key to cancel)…", "Question" } },
		false,
		{}
	)

	features.HideAllDetours()
	vim.g.detour_temp_uncover = 0
	vim.cmd([[
        let c = getchar()
        if c == "\<LeftMouse>" && v:mouse_win > 0
            let g:detour_temp_uncover=1
        endif
    ]])

	features.RevealAllDetours()

	vim.o.mouse = prev_mouse
	vim.cmd("echo '' | redraw!") -- clear the prompt

	if vim.g.detour_temp_uncover == 0 then
		vim.o.mouse = prev_mouse
		return
	end

	local m = vim.fn.getmousepos()
	local winid = util.base_at_screenpos(
		vim.api.nvim_get_current_tabpage(),
		m.screenrow,
		m.screencol
	)

	if winid then
		features.UncoverWindow(winid)
	end
end

---Close the current detour and all of its parent detours.
---
--- Finds the detour covering the current window (if any), walks up its
--- parent chain, and closes each detour from child to parent. When not inside
--- a detour, this function is a no-op.
---@return nil
function features.CloseCurrentStack()
	internal.garbage_collect()

	local current_window = vim.api.nvim_get_current_win()
	local covered = internal.get_reserved_windows(current_window)
	while covered do
		local parent = covered[1]
		vim.api.nvim_win_close(current_window, false)
		if vim.api.nvim_get_current_win() == current_window then
			-- Close operation failed
			return false
		end
		vim.fn.win_gotoid(parent)
		current_window = parent
		covered = internal.get_reserved_windows(vim.api.nvim_get_current_win())
	end

	return true
end

return features
