local M = {}

local util = require("detour.util")

---Compute float options to cover the given windows without overlapping others.
---@param coverable_windows integer[]
---@param tab_id integer
---@return table|nil
function M.construct_window_opts(coverable_windows, tab_id)
	local roots = {}
	for _, window_id in ipairs(vim.api.nvim_tabpage_list_wins(tab_id)) do
		if not util.is_floating(window_id) then
			table.insert(roots, window_id)
		end
	end

	local uncoverable_windows = {}
	for _, root in ipairs(roots) do
		if not util.contains_element(coverable_windows, root) then
			table.insert(uncoverable_windows, root)
		end
	end
	local horizontals = {}
	local verticals = {}

	for _, root in ipairs(roots) do
		local top, bottom, left, right = util.get_text_area_dimensions(root)
		horizontals[top] = 1
		horizontals[bottom] = 1
		verticals[left] = 1
		verticals[right] = 1
	end

	local floors = {}
	local sides = {}

	for top, _ in pairs(horizontals) do
		for bottom, _ in pairs(horizontals) do
			if top < bottom then
				table.insert(floors, { top, bottom })
			end
		end
	end

	for left, _ in pairs(verticals) do
		for right, _ in pairs(verticals) do
			if left < right then
				table.insert(sides, { left, right })
			end
		end
	end

	local max_area = 0
	local dimensions = nil
	for _, curr_floors in ipairs(floors) do
		local top, bottom = unpack(curr_floors)
		for _, curr_sides in ipairs(sides) do
			local left, right = unpack(curr_sides)
			local legal = true
			for _, uncoverable_window in ipairs(uncoverable_windows) do
				local uncoverable_top, uncoverable_bottom, uncoverable_left, uncoverable_right =
					util.get_text_area_dimensions(uncoverable_window)
				if not util.is_statusline_global() then -- we have to worry about statuslines
					-- The fact that we're starting with text area dimensions
					-- means that all of the rectangles we are working with do
					-- not include statuslines. This means that we need to avoid
					-- inadvertantly covering a window's status line. Neovim can
					-- be configured to only show statuslines when there are
					-- multiple windows on the screen but we can ignore that
					-- because this loop only runs when there are multiple
					-- windows on the screen.
					uncoverable_top = uncoverable_top - 1 -- don't cover above window's statusline
					uncoverable_bottom = uncoverable_bottom + 1 -- don't cover this window's statusline
				end
				local lowest_top = math.max(top, uncoverable_top)
				local highest_bottom = math.min(bottom, uncoverable_bottom)
				local rightest_left = math.max(left, uncoverable_left)
				local leftest_right = math.min(right, uncoverable_right)
				if
					(lowest_top < highest_bottom)
					and (rightest_left < leftest_right)
				then
					legal = false
				end
			end

			local area = (bottom - top) * (right - left)
			if legal and (area > max_area) then
				dimensions = { top, bottom, left, right }
				max_area = area
			end
		end
	end

	if dimensions == nil then
		vim.api.nvim_echo(
			{ { "[detour.nvim] was unable to find a spot to create a popup." } },
			true,
			{ err = true }
		)
		return nil
	end

	local top, bottom, left, right = unpack(dimensions)
	local width = right - left
	local height = bottom - top

	if height < 1 then
		vim.api.nvim_echo({
			{
				"[detour.nvim] (please file a github issue!) height is supposed to be at least 1.",
			},
		}, true, { err = true })
		return nil
	end
	if width < 1 then
		vim.api.nvim_echo({
			{
				"[detour.nvim] (please file a github issue!) width is supposed to be at least 1.",
			},
		}, true, { err = true })
		return nil
	end

	-- If a window's height extends below the UI, the window's border gets cut off.
	-- If a window's width extends beyond the UI, the window's border still shows up at the end of the UI.
	-- Using a border adds 2 to the window's height and width.
	local window_opts = {
		relative = "editor",
		row = top,
		col = left,
		width = (width - 2 > 0) and (width - 2) or width, -- create some space for borders
		height = (height - 2 > 0) and (height - 2) or height, -- create some space for borders
		border = "rounded",
		zindex = 1,
	}

	if window_opts.width > 4 then
		window_opts.width = window_opts.width - 4
		window_opts.col = window_opts.col + 2
	end

	if window_opts.height > 2 then
		window_opts.height = window_opts.height - 2
		window_opts.row = window_opts.row + 1
	end

	return window_opts
end

---Construct nested float window opts within a parent float.
---@param parent integer
---@param layer integer?
---@return table
function M.construct_nest(parent, layer)
	assert(
		util.is_open(parent),
		"trying to construct a nested window in a window that doesn't exist: ",
		parent
	)
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

return M
