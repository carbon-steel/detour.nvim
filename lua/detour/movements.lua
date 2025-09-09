---@mod detour.movements
---@brief [[
---Detour.nvim breaks window navigation commands such as
---`<C-w>w`, `<C-w>j`, or `vim.cmd.wincmd("h")`. Instead of
---using those, the user MUST use the following window navigation
---commands that this plugin provides that implements moving
---between windows while skipping over windows covered by detours.
---
---NOTE: Regular window movements such as `<C-w>w`, `<C-w>j`,
---`vim.cmd.wincmd("h")` should still work in automated
---scripts/functions. Still, you may find it more useful to use detour's
---"detour-aware" movement functions in your scripts/functions as well.
---@brief ]]

---@tag detour-movements

local movements = {}

local util = require("detour.util")
local internal = require("detour.internal")

local module_augroup = "detour-movements"
vim.api.nvim_create_augroup(module_augroup, { clear = true })

---DO NOT USE. FOR TESTING ONLY.
movements._safe_state_handler = function()
	internal.garbage_collect()
	vim.fn.win_gotoid(util.find_top_popup())
end

-- Sometimes the cursor can end up behind a detour (eg, when a window is
-- closed). In these cases just move the cursor to an appropriate place.
-- Using SafeState here means this autocmd will not interfere with automated
-- movements.
vim.api.nvim_create_autocmd({ "SafeState" }, {
	group = module_augroup,
	callback = movements._safe_state_handler,
	nested = true,
})

--- Switch to a window to the right. Skip over any non-floating windows
--- covered by a detour.
---@return nil
---@usage `
--- local detour_moves = require("detour.movements")
--- vim.keymap.set({ "n", "t" }, "<C-l>", detour_moves.DetourWinCmdL)
--- vim.keymap.set({ "n", "t" }, "<C-w>l", detour_moves.DetourWinCmdL)
--- vim.keymap.set({ "n", "t" }, "<C-w><C-l>", detour_moves.DetourWinCmdL)
---`
function movements.DetourWinCmdL()
	local covered_bases = util.find_covered_bases(
		vim.api.nvim_get_current_win()
	) or { vim.api.nvim_get_current_win() }
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

	vim.fn.win_gotoid(base)
	vim.cmd.wincmd("l")
	-- It's possible to rely on the SafeState autocmd instead of explicitly
	-- moving to the top popup, but an explicit call allows this function to work
	-- properly when used in other code.
	vim.fn.win_gotoid(util.find_top_popup())
end

--- Switch to a window to the left. Skip over any non-floating windows
--- covered by a detour.
---@return nil
---@usage `
--- local detour_moves = require("detour.movements")
--- vim.keymap.set({ "n", "t" }, "<C-h>", detour_moves.DetourWinCmdH)
--- vim.keymap.set({ "n", "t" }, "<C-w>h", detour_moves.DetourWinCmdH)
--- vim.keymap.set({ "n", "t" }, "<C-w><C-h>", detour_moves.DetourWinCmdH)
---`
function movements.DetourWinCmdH()
	local covered_bases = util.find_covered_bases(
		vim.api.nvim_get_current_win()
	) or { vim.api.nvim_get_current_win() }
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

	vim.fn.win_gotoid(base)
	vim.cmd.wincmd("h")
	vim.fn.win_gotoid(util.find_top_popup())
end

--- Switch to a window below. Skip over any non-floating windows
--- covered by a detour.
---@return nil
---@usage `
--- local detour_moves = require("detour.movements")
--- vim.keymap.set({ "n", "t" }, "<C-j>", detour_moves.DetourWinCmdJ)
--- vim.keymap.set({ "n", "t" }, "<C-w>j", detour_moves.DetourWinCmdJ)
--- vim.keymap.set({ "n", "t" }, "<C-w><C-j>", detour_moves.DetourWinCmdJ)
---`
function movements.DetourWinCmdJ()
	local covered_bases = util.find_covered_bases(
		vim.api.nvim_get_current_win()
	) or { vim.api.nvim_get_current_win() }
	table.sort(covered_bases, function(windowA, windowB)
		local _, bottomA, _, _ = util.get_text_area_dimensions(windowA)
		local _, bottomB, _, _ = util.get_text_area_dimensions(windowB)
		return bottomA > bottomB
	end)
	local base = covered_bases[1]
	for _, window in ipairs(covered_bases) do
		local _, bottom, _, _ = util.get_text_area_dimensions(window)
		if
			bottom
			~= vim.o.lines
				- vim.o.cmdheight
				- (vim.o.laststatus == 0 and 0 or 1)
		then -- subtract one for statusline
			base = window
			break
		end
	end

	vim.fn.win_gotoid(base)
	vim.cmd.wincmd("j")
	vim.fn.win_gotoid(util.find_top_popup())
end

--- Switch to a window above. Skip over any non-floating windows
--- covered by a detour.
---@return nil
---@usage `
--- local detour_moves = require("detour.movements")
--- vim.keymap.set({ "n", "t" }, "<C-k>", detour_moves.DetourWinCmdK)
--- vim.keymap.set({ "n", "t" }, "<C-w>k", detour_moves.DetourWinCmdK)
--- vim.keymap.set({ "n", "t" }, "<C-w><C-k>", detour_moves.DetourWinCmdK)
---`
function movements.DetourWinCmdK()
	local covered_bases = util.find_covered_bases(
		vim.api.nvim_get_current_win()
	) or { vim.api.nvim_get_current_win() }
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

	vim.fn.win_gotoid(base)
	vim.cmd.wincmd("k")
	vim.fn.win_gotoid(util.find_top_popup())
end

--- Switch windows in a cycle. Skip over any non-floating windows covered
--- by a detour.
---@return nil
---@usage `
--- local detour_moves = require("detour.movements")
--- vim.keymap.set({ "n", "t" }, "<C-w>", detour_moves.DetourWinCmdW)
--- vim.keymap.set({ "n", "t" }, "<C-w>w", detour_moves.DetourWinCmdW)
--- vim.keymap.set({ "n", "t" }, "<C-w><C-w>", detour_moves.DetourWinCmdW)
---`
function movements.DetourWinCmdW()
	-- We do not just repeatedly do `vim.cmd.wincmd("w")` until we hit a detour
	-- or uncovered window because doing so could form a cycle that does not
	-- include all windows.
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

	vim.fn.win_gotoid(ordered_tops[1])
end

return movements
