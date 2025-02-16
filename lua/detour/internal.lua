-- DO NOT DEPEND ON THIS FILE!
-- This is an "internal" file and can have breaking changes without warning.

local M = {}

local popup_to_coverable_windows = {}

function M.construct_augroup_name(window_id)
	return "detour-" .. window_id
end

-- Needs to be idempotent
function M.teardown_detour(window_id)
	vim.api.nvim_del_augroup_by_name(M.construct_augroup_name(window_id))
	for _, covered_window in ipairs(M.get_coverable_windows(window_id) or {}) do
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
	popup_to_coverable_windows[window_id] = nil
end

function M.get_coverable_windows(popup_id)
	if popup_to_coverable_windows[popup_id] == nil then
		return nil
	end

	-- Clean up any windows that have already been closed
	popup_to_coverable_windows[popup_id] = vim.tbl_filter(function(window_id)
		return vim.tbl_contains(vim.api.nvim_list_wins(), window_id)
	end, popup_to_coverable_windows[popup_id])

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

function M.list_popups()
	return vim.tbl_keys(popup_to_coverable_windows)
end

function M.list_coverable_windows()
	local windows = vim.api.nvim_list_wins()
	return vim.iter(vim.tbl_values(popup_to_coverable_windows))
		:flatten()
		:filter(function(w)
			return vim.tbl_contains(windows, w) -- make sure window is still open
		end)
		:totable()
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
function M.garbage_collect()
	for _, popup_id in ipairs(M.list_popups()) do
		if not vim.tbl_contains(vim.api.nvim_list_wins(), popup_id) then
			M.teardown_detour(popup_id)
		end
	end
end

assert(
	vim.fn.timer_start(
		300,
		vim.schedule_wrap(M.garbage_collect),
		{ ["repeat"] = -1 }
	) ~= -1,
	"[detour.nvim] Failed to create garbage_collect timer."
)

return M
