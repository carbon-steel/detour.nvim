local detour = require("detour")
local util = require("detour.util")
local features = require("detour.features")

function Set(list)
	local set = {}
	for _, l in ipairs(list) do
		set[l] = true
	end
	return set
end

describe("detour", function()
	before_each(function()
		vim.g.detour_testing = true
		vim.cmd([[
        %bwipeout!
        mapclear
        nmapclear
        vmapclear
        xmapclear
        smapclear
        omapclear
        mapclear
        imapclear
        lmapclear
        cmapclear
        tmapclear
        ]])
		vim.api.nvim_clear_autocmds({}) -- delete any autocmds not in a group
		for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ pattern = "*" })) do
			if vim.startswith(autocmd.group_name, "detour-") then
				vim.api.nvim_del_autocmd(autocmd.id)
			end
		end
		vim.o.splitbelow = true
		vim.o.splitright = true
	end)

	-- See Issue #25 for a discussion of duplication in this test suite.
	it("create popup", function()
		vim.cmd.view("/tmp/detour")
		local before_buffer = vim.api.nvim_get_current_buf()
		local before_window = vim.api.nvim_get_current_win()

		local after_window = assert(detour.Detour())
		local after_buffer = vim.api.nvim_get_current_buf()
		assert.are_not.same(before_window, after_window)
		assert.are.same(before_buffer, after_buffer)
		assert.True(util.is_floating(after_window))
		assert.same(#vim.api.nvim_list_wins(), 2)
	end)

	it("create nested popup over non-Detour popup", function()
		local base_buffer = vim.api.nvim_get_current_buf()
		vim.api.nvim_open_win(
			vim.api.nvim_win_get_buf(0),
			true,
			{ relative = "win", width = 12, height = 3, bufpos = { 100, 10 } }
		)

		-- See the note above regarding the duplication of this test code.
		local parent_popup = vim.api.nvim_get_current_win()
		local parent_buffer = vim.api.nvim_get_current_buf()
		assert.True(util.is_floating(parent_popup))
		local parent_config = vim.api.nvim_win_get_config(parent_popup)

		local child_popup = assert(detour.Detour())
		assert.True(util.is_floating(child_popup))
		local child_config = vim.api.nvim_win_get_config(child_popup)
		local child_buffer = vim.api.nvim_get_current_buf()
		-- The nested popup should always be on top of the parent popup
		assert.True(child_config.zindex > parent_config.zindex)

		assert.same(#vim.api.nvim_list_wins(), 3)
		assert.same(base_buffer, parent_buffer)
		assert.same(parent_buffer, child_buffer)

		vim.cmd.quit()
		assert.same(#vim.api.nvim_list_wins(), 2)
		vim.cmd.quit()
		assert.same(#vim.api.nvim_list_wins(), 1)
	end)

	-- TODO: Make sure popups are fully contained within their parents
	it("create nested popup", function()
		local base_buffer = vim.api.nvim_get_current_buf()

		local parent_popup = assert(detour.Detour())
		local parent_buffer = vim.api.nvim_get_current_buf()
		assert.True(util.is_floating(parent_popup))
		local parent_config = vim.api.nvim_win_get_config(parent_popup)

		local child_popup = assert(detour.Detour())
		assert.True(util.is_floating(child_popup))
		local child_config = vim.api.nvim_win_get_config(child_popup)
		local child_buffer = vim.api.nvim_get_current_buf()
		-- The nested popup should always be on top of the parent popup
		assert.True(child_config.zindex > parent_config.zindex)

		assert.same(#vim.api.nvim_list_wins(), 3)
		assert.same(base_buffer, parent_buffer)
		assert.same(parent_buffer, child_buffer)

		vim.cmd.quit()
		assert.same(#vim.api.nvim_list_wins(), 2)
		vim.cmd.quit()
		assert.same(#vim.api.nvim_list_wins(), 1)
	end)

	it("react to a coverable window closing", function()
		pending(
			"WinResized doesn't seem to work when running nvim as a command."
		)
		vim.cmd.wincmd("v")
		local coverable_window = vim.api.nvim_get_current_win()
		local popup = assert(detour.Detour())
		vim.fn.win_gotoid(coverable_window)
		vim.cmd.wincmd("s")
		local uncoverable_win = vim.api.nvim_get_current_win()
		vim.fn.win_gotoid(coverable_window)
		vim.cmd.close()

		assert.False(util.overlap(popup, uncoverable_win))
	end)

	it("create popup over current window", function()
		local window_a = vim.api.nvim_get_current_win()
		vim.cmd.wincmd("s")
		local window_b = vim.api.nvim_get_current_win()
		local popup_b = assert(detour.DetourCurrentWindow())
		assert.False(util.overlap(window_a, popup_b))
		assert.True(util.overlap(window_b, popup_b))
		vim.fn.win_gotoid(window_a)
		local popup_a = assert(detour.Detour())
		assert.True(util.overlap(window_a, popup_a))
		assert.False(util.overlap(window_b, popup_a))
	end)

	it("Do not allow two popups over the same window", function()
		local win = vim.api.nvim_get_current_win()
		local popup = assert(detour.Detour())
		vim.fn.win_gotoid(win)
		assert.Nil(detour.Detour())
		assert.same(Set({ win, popup }), Set(vim.api.nvim_tabpage_list_wins(0)))

		vim.fn.win_gotoid(win)
		assert.Nil(detour.DetourCurrentWindow())
		assert.same(Set({ win, popup }), Set(vim.api.nvim_tabpage_list_wins(0)))
	end)

	it(
		"Do not allow two 'current window' popups over the same window",
		function()
			local win = vim.api.nvim_get_current_win()
			local popup = assert(detour.DetourCurrentWindow())
			vim.fn.win_gotoid(win)
			assert.Nil(detour.DetourCurrentWindow())
			assert.same(
				Set({ win, popup }),
				Set(vim.api.nvim_tabpage_list_wins(0))
			)

			vim.fn.win_gotoid(win)
			assert.Nil(detour.Detour())
			assert.same(
				Set({ win, popup }),
				Set(vim.api.nvim_tabpage_list_wins(0))
			)
		end
	)

	it("Switch focus to a popup's floating parent when it's closed", function()
		vim.api.nvim_open_win(
			vim.api.nvim_win_get_buf(0),
			true,
			{ relative = "win", width = 12, height = 3, bufpos = { 100, 10 } }
		)

		local wins = { vim.api.nvim_get_current_win() }
		for _ = 1, 10 do
			table.insert(wins, detour.Detour())
			for j, win in ipairs(wins) do
				assert(win)
				assert.same(
					vim.api.nvim_win_get_config(win).focusable,
					j == #wins
				)
			end
		end

		for _ = 1, 10 do
			table.remove(wins, #wins)
			local done = false
			vim.api.nvim_create_autocmd("User", {
				pattern = "DetourGoTo" .. wins[#wins],
				callback = function()
					done = true
				end,
				once = true,
			})
			vim.cmd.close()
			assert(vim.wait(10, function()
				return done
			end))
			assert.same(vim.api.nvim_get_current_win(), wins[#wins])
			for j, win in ipairs(wins) do
				assert.same(
					vim.api.nvim_win_get_config(win).focusable,
					j == #wins
				)
			end
		end
	end)

	it("Switch focus to a popup's parent when it's closed", function()
		local wins = { vim.api.nvim_get_current_win() }
		for _ = 1, 10 do
			table.insert(wins, detour.Detour())
			for j, win in ipairs(wins) do
				assert(win)
				if j > 1 then -- the base window cannot be unfocusable
					assert.same(
						vim.api.nvim_win_get_config(win).focusable,
						j == #wins
					)
				end
			end
		end

		for _ = 1, 10 do
			table.remove(wins, #wins)
			local done = false
			vim.api.nvim_create_autocmd("User", {
				pattern = "DetourGoTo" .. wins[#wins],
				callback = function()
					done = true
				end,
				once = true,
			})
			vim.cmd.close()
			assert(vim.wait(10, function()
				return done
			end))
			assert.same(vim.api.nvim_get_current_win(), wins[#wins])
			for j, win in ipairs(wins) do
				if j > 1 then -- the base window cannot be unfocusable
					assert.same(
						vim.api.nvim_win_get_config(win).focusable,
						j == #wins
					)
				end
			end
		end
	end)

	it("Always move focus to top popup", function()
		pending("WinEnter doesn't work when running nvim as a command.")
		local popup = assert(detour.Detour())
		vim.cmd.split()
		assert.same(vim.api.nvim_get_current_win(), popup)
	end)

	it(
		"Handle cases when popups close without throwing a WinClosed event",
		function()
			pending(
				"WinResized doesn't seem to work when running nvim as a command."
			)
			vim.cmd.vsplit()
			local popup = assert(detour.DetourCurrentWindow())
			vim.api.nvim_create_autocmd({ "WinLeave" }, {
				callback = function()
					vim.api.nvim_win_close(0, true)
					return true
				end,
			})
			vim.cmd.wincmd("h")
			assert.False(util.is_open(popup))
			vim.cmd.wincmd("l")
			assert(detour.DetourCurrentWindow())
		end
	)

	it("Test CloseOnLeave", function()
		local popup_id = assert(detour.Detour())
		features.CloseOnLeave(popup_id)
		assert.True(util.is_open(popup_id))
		vim.cmd.wincmd("w")
		assert.False(util.is_open(popup_id))

		popup_id = assert(detour.Detour())
		features.CloseOnLeave(popup_id)
		assert.True(util.is_open(popup_id))
		vim.cmd.split()
		assert.False(util.is_open(popup_id))
	end)

	it("Test ShowPathInTitle", function()
		vim.cmd.file("/tmp/detour_test_a")
		local popup_id = assert(detour.Detour())
		assert.same(
			"/tmp/detour_test_a",
			vim.api.nvim_win_get_config(0).title[1][1]
		)
		vim.cmd.file("/tmp/detour_test_b")
		-- Simulate the event triggered by the `on_win` decorator
		vim.cmd.doautocmd("User DetourUpdateTitle" .. util.stringify(popup_id))
		assert.same(
			"/tmp/detour_test_b",
			vim.api.nvim_win_get_config(0).title[1][1]
		)
	end)
end)
