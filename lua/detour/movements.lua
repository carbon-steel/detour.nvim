---@brief [[
--- The `detour.movements` module introduces backward-incompatible changes.
--- Users who `require` this module will enable autocmds that enhance their
--- window switching to be "detour-aware". Those who do not require this module
--- will keep the standard window switching behavior. Encapsulating this logic
--- in a module allows users to opt-in to the new behavior instead of having the
--- behavior change from under their feet.
---@brief ]]

---@tag detour.movements

local M = {}

local util = require("detour.util")

-- detour_use_smart_window_movement will be set to true most of the time and
-- only set to false during specific operations. This is an internal variable
-- and the user should never touch it.
vim.g["detour_use_smart_window_movement"] = true

local module_augroup = "detour-movements"
vim.api.nvim_create_augroup(module_augroup, { clear = true })

vim.api.nvim_create_autocmd({ "WinEnter" }, {
	group = module_augroup,
	callback = function()
		if vim.g["detour_use_smart_window_movement"] then
			vim.fn.win_gotoid(util.find_top_popup())
		end
	end,
})

--- Switch windows to the right in "detour-aware" fashion.
---
--- If moving away from a detour, move first to a base window and perform
--- `vim.cmd.wincmd('l').`
---
--- If arriving into a window covered by a detour, switch into that detour.
function M.DetourWinCmdL()
	local covered_bases =
		util.find_covered_bases(vim.api.nvim_get_current_win())
	table.sort(covered_bases, function(windowA, windowB)
		local _, _, _, rightA = util.get_text_area_dimensions(windowA)
		local _, _, _, rightB = util.get_text_area_dimensions(windowB)
		return rightA > rightB
	end)
	local base = covered_bases[1]
	for _, window in ipairs(covered_bases) do
		local _, _, _, right = util.get_text_area_dimensions(window)
		if right ~= vim.o.columns then
			base = window
			break
		end
	end

	if base then
		vim.g["detour_use_smart_window_movement"] = false
		vim.fn.win_gotoid(base)
		vim.g["detour_use_smart_window_movement"] = true
		vim.cmd.wincmd("l")
		if vim.g["detour_use_smart_window_movement"] then
			vim.fn.win_gotoid(util.find_top_popup())
		end
	end
end

--- Switch windows to the left in "detour-aware" fashion.
---
--- If moving away from a detour, move first to a base window and perform
--- `vim.cmd.wincmd('h').`
---
--- If arriving into a window covered by a detour, switch into that detour.
function M.DetourWinCmdH()
	local covered_bases =
		util.find_covered_bases(vim.api.nvim_get_current_win())
	table.sort(covered_bases, function(windowA, windowB)
		local _, _, leftA, _ = util.get_text_area_dimensions(windowA)
		local _, _, leftB, _ = util.get_text_area_dimensions(windowB)
		return leftA < leftB
	end)
	local base = covered_bases[1]
	for _, window in ipairs(covered_bases) do
		local _, _, left, _ = util.get_text_area_dimensions(window)
		if left ~= 0 then
			base = window
			break
		end
	end

	if base then
		vim.g["detour_use_smart_window_movement"] = false
		vim.fn.win_gotoid(base)
		vim.g["detour_use_smart_window_movement"] = true
		vim.cmd.wincmd("h")
		if vim.g["detour_use_smart_window_movement"] then
			vim.fn.win_gotoid(util.find_top_popup())
		end
	end
end

--- Switch windows downwards in "detour-aware" fashion.
---
--- If moving away from a detour, move first to a base window and perform
--- `vim.cmd.wincmd('j').`
---
--- If arriving into a window covered by a detour, switch into that detour.
function M.DetourWinCmdJ()
	local covered_bases =
		util.find_covered_bases(vim.api.nvim_get_current_win())
	table.sort(covered_bases, function(windowA, windowB)
		local _, bottomA, _, _ = util.get_text_area_dimensions(windowA)
		local _, bottomB, _, _ = util.get_text_area_dimensions(windowB)
		return bottomA > bottomB
	end)
	local base = covered_bases[1]
	for _, window in ipairs(covered_bases) do
		local _, bottom, _, _ = util.get_text_area_dimensions(window)
		if bottom ~= vim.o.lines then
			base = window
			break
		end
	end

	if base then
		vim.g["detour_use_smart_window_movement"] = false
		vim.fn.win_gotoid(base)
		vim.g["detour_use_smart_window_movement"] = true
		vim.cmd.wincmd("j")
		if vim.g["detour_use_smart_window_movement"] then
			vim.fn.win_gotoid(util.find_top_popup())
		end
	end
end

--- Switch windows upwards in "detour-aware" fashion.
---
--- If moving away from a detour, move first to a base window and perform
--- `vim.cmd.wincmd('k').`
---
--- If arriving into a window covered by a detour, switch into that detour.
function M.DetourWinCmdK()
	local covered_bases =
		util.find_covered_bases(vim.api.nvim_get_current_win())
	table.sort(covered_bases, function(windowA, windowB)
		local topA, _, _, _ = util.get_text_area_dimensions(windowA)
		local topB, _, _, _ = util.get_text_area_dimensions(windowB)
		return topA < topB
	end)
	local base = covered_bases[1]
	for _, window in ipairs(covered_bases) do
		local top, _, _, _ = util.get_text_area_dimensions(window)
		if top ~= 0 then
			base = window
			break
		end
	end

	if base then
		vim.g["detour_use_smart_window_movement"] = false
		vim.fn.win_gotoid(base)
		vim.cmd.wincmd("k")
		vim.fn.win_gotoid(util.find_top_popup())
		vim.g["detour_use_smart_window_movement"] = true
	end
end

--- Switch windows in a cycle in "detour-aware" fashion.
---
--- Calls `vim.cmd.wincmd('w')` if arriving into a window covered by a detour,
--- switch into that detour.
function M.DetourWinCmdW()
	local windows = vim.api.nvim_tabpage_list_wins(0)
	local current_top = util.find_top_popup()

	-- Collect all the top detour or naked base windows.
	local tops = {}
	for _, window in ipairs(windows) do
		tops[util.find_top_popup(window)] = true
	end

	-- Sort all the top windows. Filter out the windows ordered before the
	-- current top.
	local ordered_tops = {}
	for top in vim.spairs(tops) do
		if top > current_top then
			ordered_tops[#ordered_tops + 1] = top
		end
	end

	-- In tops is empty, add the first top so that we cycle back to the
	-- beginning of the list.
	for top in vim.spairs(tops) do
		ordered_tops[#ordered_tops + 1] = top
		break
	end

	vim.g["detour_use_smart_window_movement"] = false
	vim.fn.win_gotoid(ordered_tops[1])
	vim.g["detour_use_smart_window_movement"] = true
end

return M
