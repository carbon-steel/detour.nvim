local M = {}

local util = require("detour.util")

local function update_title(window_id)
	-- Assumption: window_id is not closed as this was triggered from the fact that we are redrawing this window.
	local buffer_id = vim.api.nvim_win_get_buf(window_id)
	local path = vim.api.nvim_buf_get_name(buffer_id)
	local tabwin = vim.fn.win_id2tabwin(window_id)
	if tabwin == { 0, 0 } then
		return
	end
	local tabnr, winnr = unpack(tabwin)
	local home = vim.fn.getcwd(winnr, tabnr)
	local title = vim.fn.fnamemodify(path, ":.")
	if title:sub(1, #home) == home then
		title = title:sub(#home + 1)
	end
	vim.api.nvim_win_set_config(
		window_id,
		vim.tbl_extend("force", vim.api.nvim_win_get_config(window_id), { title = title })
	)
end

function M.ShowPathInTitle(popup_id)
	require("detour.show_path_in_title")
	update_title(popup_id)

	vim.api.nvim_create_autocmd({ "User" }, {
		pattern = "DetourUpdateTitle" .. util.stringify(popup_id),
		group = util.construct_augroup_name(popup_id),
		callback = function()
			update_title(popup_id)
		end,
	})
end

function M.CloseOnLeave(popup_id)
	-- This autocmd will close the created detour popup when you focus on a different window.
	vim.api.nvim_create_autocmd({ "WinEnter" }, {
		group = util.construct_augroup_name(popup_id),
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
	})
end

return M
