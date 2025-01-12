# Display help files in a Detour window

```lua
vim.keymap.set("n", "<A-h>", function()
	local popup_id = require("detour").Detour()
	if popup_id then
		require("telescope.builtin").live_grep({
			cwd = vim.fs.joinpath(vim.env.VIMRUNTIME, "doc"),
		})
	else
		local keys = vim.api.nvim_replace_termcodes(":h ", true, true, true)
		vim.api.nvim_feedkeys(keys, "n", true)
	end
end)
```
