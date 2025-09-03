local M = {}

---@class detour.util
---@field Set fun(list: any[]): table<any, boolean>
---@field contains_element fun(array: any[], target: any): boolean
---@field contains_key fun(array: table, target: any): boolean
---@field contains_value fun(array: table, target: any): boolean
---@field get_text_area_dimensions fun(window_id: integer): integer, integer, integer, integer
---@field is_floating fun(window_id: integer): boolean
---@field get_maybe_zindex fun(window_id: integer): integer|nil
---@field overlap fun(window_a: integer, window_b: integer): boolean
---@field find_top_popup fun(window?: integer): integer
---@field find_covered_bases fun(window_id: integer): integer[]|nil
---@field find_covered_windows fun(window_id: integer): integer[]
---@field is_open fun(window_id: integer): boolean
---@field stringify fun(number: integer): string
---@field pairs_by_keys fun(t: table, f?: fun(a:any,b:any):boolean): fun(): any, any
---@field is_statusline_global fun(): boolean
---@field base_at_screenpos fun(tab_id: integer, screenrow: integer, screencol: integer): integer|nil

local internal = require("detour.internal")

---@param list any[]
---@return table<any, boolean>
function M.Set(list)
	local set = {}
	for _, l in ipairs(list) do
		set[l] = true
	end
	return set
end

---@param array any[]
---@param target any
---@return boolean
function M.contains_element(array, target)
	for _, value in ipairs(array) do
		if value == target then
			return true
		end
	end
	return false
end

---@param array table
---@param target any
---@return boolean
function M.contains_key(array, target)
	for key, _ in pairs(array) do
		if key == target then
			return true
		end
	end
	return false
end

---@param array table
---@param target any
---@return boolean
function M.contains_value(array, target)
	for _, value in pairs(array) do
		if value == target then
			return true
		end
	end
	return false
end

--- Returns the positions of top, bottom, left, and right of a given window's text area.
--- The statusline is not included in the text area. Bottom and right are exclusive.
---@param window_id integer
---@return integer top, integer bottom, integer left, integer right
function M.get_text_area_dimensions(window_id)
	local top, left = unpack(vim.api.nvim_win_get_position(window_id))
	local bottom = top + vim.api.nvim_win_get_height(window_id)
	local right = left + vim.api.nvim_win_get_width(window_id)
	return top, bottom, left, right
end

---@param window_id integer
---@return boolean
function M.is_floating(window_id)
	return vim.api.nvim_win_get_config(window_id).relative ~= ""
end

--- Returns the zindex for the given window, if floating, otherwise nil.
---@param window_id integer
---@return integer|nil
function M.get_maybe_zindex(window_id)
	return vim.api.nvim_win_get_config(window_id).zindex
end

---@param positions_a { [1]: integer, [2]: integer, [3]: integer, [4]: integer }
---@param positions_b { [1]: integer, [2]: integer, [3]: integer, [4]: integer }
---@return boolean
local function overlap_helper(positions_a, positions_b)
	local top_a, bottom_a, left_a, right_a = unpack(positions_a)
	local top_b, bottom_b, left_b, right_b = unpack(positions_b)
	if math.max(left_a, left_b) >= math.min(right_a, right_b) then
		return false
	end

	if math.max(top_a, top_b) >= math.min(bottom_a, bottom_b) then
		return false
	end

	return true
end

---@param window_a integer
---@param window_b integer
---@return boolean
function M.overlap(window_a, window_b)
	return overlap_helper(
		{ M.get_text_area_dimensions(window_a) },
		{ M.get_text_area_dimensions(window_b) }
	)
end

---@param window? integer
---@return integer window_id
function M.find_top_popup(window)
	local window_id = window or vim.api.nvim_get_current_win()
	local all_coverable_windows = internal.list_reserved_windows()
	for _, popup in ipairs(internal.list_popups()) do
		if
			not vim.list_contains(all_coverable_windows, popup) -- ignore popups with popups nested in them
			and vim.tbl_contains(M.find_covered_windows(popup), window_id)
		then
			return popup
		end
	end
	return window_id -- no popup that covers the current window was found
end

-- Finds all base windows that are covered by the provided popup.
-- If the provided window is not a popup, returns the given argument.
---@param window_id integer
---@return integer[]|nil
function M.find_covered_bases(window_id)
	assert(M.is_open(window_id), tostring(window_id) .. " is not open")
	local current_window = window_id
	local coverable_bases = nil
	while internal.get_reserved_windows(current_window) do
		coverable_bases = internal.get_reserved_windows(current_window) or {}
		assert(
			#coverable_bases > 0,
			"[detour.nvim] There should never be an empty array in popup_to_covered_windows."
		)
		-- We iterate on only the first covered window because there are two cases:
		-- A: there is exactly one covered window and it's another detour.
		-- B: there is one or more covered windows and none of them are detours. We've found our covered base windows. Hence, this would be the last iteration of this loop.
		current_window = coverable_bases[1]
	end

	-- This covers the case where the window_id is not a detour popup and we never enter the above loop.
	if coverable_bases == nil then
		return nil
	end

	return vim.tbl_filter(function(base)
		return M.overlap(base, window_id)
	end, coverable_bases)
end

-- Finds all windows that are covered by the provided popup.
-- If the provided window is not a popup, returns the given argument.
---@param window integer
---@return integer[]
function M.find_covered_windows(window)
	local current_window = window
	local coverable_windows = {}
	while internal.get_reserved_windows(current_window) do
		coverable_windows[#coverable_windows + 1] =
			internal.get_reserved_windows(current_window)
		assert(
			#coverable_windows[#coverable_windows] > 0,
			"[detour.nvim] There should never be an empty array in popup_to_covered_windows."
		)
		-- We iterate on only the first covered window because there are two cases:
		-- A: there is exactly one covered window and it's another detour.
		-- B: there is one or more covered windows and none of them are detours. We've found our covered base windows. Hence, this would be the last iteration of this loop.
		current_window = coverable_windows[#coverable_windows][1]
	end

	if #coverable_windows == 0 then
		return { window }
	end

	return vim.iter(coverable_windows)
		:flatten()
		:filter(function(other)
			return M.overlap(other, window)
		end)
		:totable()
end

---@param window_id integer
---@return boolean
function M.is_open(window_id)
	return vim.tbl_contains(vim.api.nvim_list_wins(), window_id)
end

---@param number integer
---@return string
function M.stringify(number)
	local base = string.byte("a")
	local values = {}
	for digit in ("" .. number):gmatch(".") do
		values[#values + 1] = tonumber(digit) + base
	end
	return string.char(unpack(values))
end

---@param t table
---@param f? fun(a:any,b:any):boolean
---@return fun(): any, any
function M.pairs_by_keys(t, f)
	local a = {}
	for n in pairs(t) do
		table.insert(a, n)
	end
	table.sort(a, f)
	local i = 0 -- iterator variable
	local iter = function() -- iterator function
		i = i + 1
		if a[i] == nil then
			return nil
		else
			return a[i], t[a[i]]
		end
	end
	return iter
end

---Whether the statusline is global (laststatus == 3).
---@return boolean
function M.is_statusline_global()
	-- When laststatus == 3, Neovim uses a single global statusline
	-- and individual windows do not have their own.
	return vim.o.laststatus == 3
end

---Find non-floating window at a given screen position (1-based)
---@param tab_id integer
---@param screenrow integer
---@param screencol integer
---@return integer|nil
function M.base_at_screenpos(tab_id, screenrow, screencol)
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab_id)) do
		if not M.is_floating(win) then
			local winnr = vim.fn.win_id2win(win)
			assert(winnr ~= 0, tostring(win) .. " was not found")
			local top, left = unpack(vim.fn.win_screenpos(winnr))
			assert(top ~= 0 and left ~= 0, tostring(winnr) .. " was not found")
			local width = vim.fn.winwidth(winnr) -- includes signs/number column
			local height = vim.fn.winheight(winnr)
			if
				screenrow >= top
				and screenrow
					< top
						+ height
						+ (M.is_statusline_global() and 0 or 1) -- for per-window statusline
						+ 1 -- for the border and global statusline
				and screencol >= left
				and screencol < left + width
			then
				return win
			end
		end
	end
	return nil
end

return M
