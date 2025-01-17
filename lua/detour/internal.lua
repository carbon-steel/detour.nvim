-- DO NOT DEPEND ON THIS FILE!
-- This is an "internal" file and can have breaking changes without warning.

local M = {}

local popup_to_coverable_windows = {}

function M.get_coverable_windows(popup_id)
	if popup_to_coverable_windows[popup_id] == nil then
		return nil
	end

	-- Clean up any windows that have already been closed
	popup_to_coverable_windows[popup_id] = vim.tbl_filter(function(window_id)
		return vim.tbl_contains(vim.api.nvim_list_wins(), window_id)
	end, popup_to_coverable_windows[popup_id])

	assert(
		#popup_to_coverable_windows[popup_id] > 0,
		"[detour.nvim] Popups should always have at least one coverable window. This may indicate that this popup needs to be closed."
	)
	return popup_to_coverable_windows[popup_id]
end

function M.record_popup(popup_id, coverable_windows)
	local open_windows = vim.api.nvim_list_wins()
	coverable_windows = vim.tbl_filter(function(window_id)
		return vim.tbl_contains(open_windows, window_id)
	end, coverable_windows)

	if #coverable_windows == 0 then
		vim.api.nvim_err_writeln(
			"[detour.nvim] You must provide at least one valid (open) coverable window."
		)
		return false
	end
	popup_to_coverable_windows[popup_id] = coverable_windows
	return true
end

function M.erase_popup(popup_id)
	popup_to_coverable_windows[popup_id] = nil
end

function M.list_popups()
	return vim.tbl_keys(popup_to_coverable_windows)
end

function M.list_coverable_windows()
	return vim.tbl_flatten(vim.tbl_values(popup_to_coverable_windows))
end

return M
