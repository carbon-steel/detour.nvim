# detour.nvim

> It's a dangerous business, Frodo, going out your door. You step onto the road, and if you don't keep your feet, there's no knowing where you might be swept off to.

<div dir="rtl">
J.R.R. Tolkien, The Lord of the Rings
</div>
</br></br>

`detour.nvim` provides commands to open floating windows that position and shape
themselves. It makes floating windows a viable alternative to split windows.

# Never lose your spot!📍🗺️

| What does detour.nvim do? | |
| :--: | :--: |
| `:Detour`/`require('detour').Detour()` <br />opens a floating window<br />over all current windows | ![detour](https://github.com/carbon-steel/detour.nvim/assets/7697639/1eb85155-7134-473f-8df0-dd15f55c1d8c) |
| `:DetourCurrentWindow`/<br />`require('detour').DetourCurrentWindow()`<br />opens a floating window over<br />only the current window | ![detour2](https://github.com/carbon-steel/detour.nvim/assets/7697639/d3f0db15-916b-4b17-b227-0e4aa8fc318d) |
| Works with Neovim's `:split`/`:vsplit`/`<C-w>s`/`<C-w>v`/`<C-w>T` commands | ![split](https://github.com/carbon-steel/detour.nvim/assets/7697639/4ffa7f36-8b2a-4d91-a8bb-7012f7b82015) |
| You can nest detour popups | ![nest](https://github.com/carbon-steel/detour.nvim/assets/7697639/5fc3cad6-9acf-482d-97cb-c75788617cf8) |
| Example usage: Open a popup <br />-> Go to different file <br />-> Create vertical split <br />-> Close popup | ![basic](https://github.com/carbon-steel/detour.nvim/assets/7697639/3a408a14-8b9d-4bd4-90db-e633c5f97b7c) |

Neovim's floating windows are a great utility to use in plugins and
functions, but they cannot be used manually. This is because
creating floats is not simple like calling `:split` or `:vsplit`.
`vim.api.nvim_open_win(...)` requires coordinates and dimensions to make
a float which is too tedious to do by hand.

Detour.nvim brings a single new feature to Neovim: **detour windows** (aka
detours). Detours are floating windows with the ease-of-use of splits.

Detours will make sure not to overlap each other unless when a detour is
nested within another.

# Installation

### Lazy.nvim

```lua
{ "carbon-steel/detour.nvim",
    config = function ()
        require("detour").setup({
            -- Put custom configuration here
        })
        vim.keymap.set('n', '<c-w><enter>', ":Detour<cr>")
        vim.keymap.set('n', '<c-w>.', ":DetourCurrentWindow<cr>")

        local detour_moves = require("detour.movements")
        -- This is an example set of keymaps, but if you use other keys to
        -- navigate windows, changes these keymaps to suit your situation.
        vim.keymap.set({ "n", "t" }, "<C-j>", detour_moves.DetourWinCmdJ)
        vim.keymap.set({ "n", "t" }, "<C-w>j", detour_moves.DetourWinCmdJ)
        vim.keymap.set({ "n", "t" }, "<C-w><C-j>", detour_moves.DetourWinCmdJ)

        vim.keymap.set({ "n", "t" }, "<C-h>", detour_moves.DetourWinCmdH)
        vim.keymap.set({ "n", "t" }, "<C-w>h", detour_moves.DetourWinCmdH)
        vim.keymap.set({ "n", "t" }, "<C-w><C-h>", detour_moves.DetourWinCmdH)

        vim.keymap.set({ "n", "t" }, "<C-k>", detour_moves.DetourWinCmdK)
        vim.keymap.set({ "n", "t" }, "<C-w>k", detour_moves.DetourWinCmdK)
        vim.keymap.set({ "n", "t" }, "<C-w><C-k>", detour_moves.DetourWinCmdK)

        vim.keymap.set({ "n", "t" }, "<C-l>", detour_moves.DetourWinCmdL)
        vim.keymap.set({ "n", "t" }, "<C-w>l", detour_moves.DetourWinCmdL)
        vim.keymap.set({ "n", "t" }, "<C-w><C-l>", detour_moves.DetourWinCmdL)

        vim.keymap.set({ "n", "t" }, "<C-w>w", detour_moves.DetourWinCmdW)
        vim.keymap.set({ "n", "t" }, "<C-w><C-w>", detour_moves.DetourWinCmdW)

    end
},
```

# Example keymaps

`detour.nvim` is designed as a utility library for keymaps people can write on their own.

**NOTE** If you'd like to share a keymap you made, please submit it in a github issue and we'll include it in the `examples` directory!

Here are a few basic examples...

### Open your Neovim config

```lua
vim.keymap.set("n", "<leader>e", function()
	require("detour").Detour()
	vim.cmd.edit(vim.fn.stdpath("config"))
end)
```

### Jump to definition in detour

```lua
vim.keymap.set("n", "<leader>gd", function()
	if not require("detour").Detour() then
		return
	end
	vim.lsp.buf.definition()
end)
```

### Use with Telescope

Select a terminal buffer to open in a detour

This is a simple example but there is a better keymap in `examples/telescope.md` that also opens a new terminal when no terminals are found.

```lua
vim.keymap.set("n", "<leader>t", function()
	local window_id = require("detour").Detour() -- Open a detour
	if not window_id then
		return
	end

	-- Switch to a blank buffer.
	-- This is a necessary precaution because the following call to telescope's
	-- `buffers` function may fail to bring up a prompt if it does not find any
	-- qualifying buffers. In that case, the call to `nvim_feedkeys` will
	-- write to this blank buffer instead of whatever buffer `Detour` opened
	-- with.
	vim.cmd.enew()
	vim.bo.bufhidden = "delete" -- delete this scratch buffer when we move out of it
	vim.wo[window_id].signcolumn = "no"

	require("telescope.builtin").buffers({}) -- Open telescope prompt
	vim.api.nvim_feedkeys("term://", "n", true) -- popuplate prompt with "term"
end)
```

||
|:--:|
| **Open two terminal buffers -> Use the keymap above -> Select desired terminal** |
| ![term](https://github.com/carbon-steel/detour.nvim/assets/7697639/775cd697-d47e-4d3c-9aaf-9f7f86c266f0) |

### Wrap a TUI: top

You can wrap any TUI in a detour. Here is an example.

Run `top` in a detour:

```lua
vim.keymap.set("n", "<leader>p", function()
	local window_id = require("detour").Detour() -- open a detour
	if not window_id then
		return
	end

	vim.cmd.terminal("top") -- open a terminal buffer
	vim.bo.bufhidden = "delete" -- close the terminal when window closes
	vim.wo[window_id].signcolumn = "no" -- In Neovim 0.10, the signcolumn can push the TUI a bit out of window

	-- It's common for people to have `<Esc>` mapped to `<C-\><C-n>` for terminals.
	-- This can get in the way when interacting with TUIs.
	-- This maps the escape key back to itself (for this buffer) to fix this problem.
	vim.keymap.set("t", "<Esc>", "<Esc>", { buffer = true })

	vim.cmd.startinsert() -- go into insert mode

	vim.api.nvim_create_autocmd({ "TermClose" }, {
		buffer = vim.api.nvim_get_current_buf(),
		callback = function()
			-- This automated keypress skips for you the "[Process exited 0]" message
			-- that the embedded terminal shows.
			vim.api.nvim_feedkeys("i", "n", false)
		end,
	})
end)
```

||
| :--: |
| **Use keymap above -> Close window** |
![top](https://github.com/carbon-steel/detour.nvim/assets/7697639/49dd12ab-630b-4558-9486-fe82cc94882c)

### Wrap a TUI: tig

Run `tig` in a detour:

```lua
vim.keymap.set("n", "<leader>g", function()
	local current_dir = vim.fn.expand("%:p:h")
	local window_id = require("detour").Detour() -- open a detour
	if not window_id then
		return
	end

	-- Set this window's current working directory to current file's directory.
	-- tig finds a git repo based on the current working directory.
	vim.cmd.lcd(current_dir)

	vim.cmd.terminal("tig") -- open a terminal buffer running tig
	vim.bo.bufhidden = "delete" -- close the terminal when window closes
	vim.wo[window_id].signcolumn = "no" -- In Neovim 0.10, the signcolumn can push the TUI a bit out of window

	-- It's common for people to have `<Esc>` mapped to `<C-\><C-n>` for terminals.
	-- This can get in the way when interacting with TUIs.
	-- This maps the escape key back to itself (for this buffer) to fix this problem.
	vim.keymap.set("t", "<Esc>", "<Esc>", { buffer = true })

	vim.cmd.startinsert() -- go to insert mode

	vim.api.nvim_create_autocmd({ "TermClose" }, {
		buffer = vim.api.nvim_get_current_buf(),
		callback = function()
			-- This automated keypress skips for you the "[Process exited 0]" message
			-- that the embedded terminal shows.
			vim.api.nvim_feedkeys("i", "n", false)
		end,
	})
end)
```

||
|:--:|
| **Use keymap above -> Close window** |
| ![tig2](https://github.com/carbon-steel/detour.nvim/assets/7697639/7dd84b42-26d8-487b-8486-aa08e0fef5c8) |

# Options

| Option  | Description                                                                                 | Default value |
| --      | --                                                                                          | --            |
| `title` | "path" sets the path of the current buffer as the title of the float. "none" sets no title. | "path"        |

# Development

* Build help docs: run `make help` from the repo root.
    - Requires `lemmy-help` in your PATH ([repo](https://github.com/numToStr/lemmy-help/tree/master)).
    - Optional: Neovim available for generating `helptags` (target does not fail if absent).
* Run test: run `make test` from the repo root
    - Requires `docker`

# FAQ

> I want to convert detours to splits or tabs.

`<C-w>s` and `<C-w>v` can be used from within a popup to create splits. `<C-w>T` creates tabs.

> My LSP keeps moving my cursor to other windows.

If your LSP movements (ex: `go-to-definition`) are opening locations in other windows, make sure that `reuse_win` is set to `false`.

> My floating windows don't look good.

Some colorschemes don't have visually clear floating window border colors. Consider customizing your colorscheme's FloatBorder to a color that makes your floating windows clearer.

> My TUI is slightly wider than the floating window it's in.

This is something I noticed happening when I upgraded to Neovim 0.10. After you create your detour floating window, make sure to turn off `signcolumn`.

```lua
vim.opt.signcolumn = "no"
```
