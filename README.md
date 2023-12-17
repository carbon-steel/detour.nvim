# detour.nvim
> It's a dangerous business, Frodo, going out your door. You step onto the road, and if you don't keep your feet, there's no knowing where you might be swept off to.

<div dir="rtl">
J.R.R. Tolkien, The Lord of the Rings 
</div>
</br></br>

![detour](https://github.com/carbon-steel/detour.nvim/assets/7697639/63a88fd3-f910-4e42-9664-0e14fe88d066)

# Never lose your spot!📍🗺️
> What does detour.nvim do?

Provides the `:Detour` command *(and `require('detour').Detour()` in lua)* that opens a popup window.

`detour.nvim` has two uses:
* Use popup windows instead of split windows
  
  :+1: Popups preserve your position in the current file during detours into other files *(just like splits)*

  :+1: Popups can use the entire screen *(unlike splits)*

* Provide a large popup windows for TUIs, scripts, and commands.
    * This plugin can be considered a generalized version of [`toggleterm.nvim`](https://github.com/akinsho/toggleterm.nvim) and [`lazygit.nvim`](https://github.com/kdheepak/lazygit.nvim).

| Basic Usage |
| :--: |
| **Open a popup -> Go to different file -> Create vertical split -> Close popup** |
| ![basic](https://github.com/carbon-steel/detour.nvim/assets/7697639/3a408a14-8b9d-4bd4-90db-e633c5f97b7c) |

# Installation

### Lazy.nvim

```lua
{ "carbon-steel/detour.nvim",
    config = function ()
       vim.keymap.set('n', '<c-w><enter>', ":Detour<cr>")
   end
},
```

# Example keymaps
`detour.nvim` is designed as a utility library for keymaps people can write on their own.

**NOTE** If you'd like to share a keymap you made, please submit it in a github issue and we'll include it in the `examples` directory!

Here are a few basic examples...

### Use with Telescope
Select a terminal buffer to open in a popup

This is a simple example but there is a better keymap in `examples/telescope.md` that also opens a new terminal when no terminals are found.
```lua
vim.keymap.set('n', '<leader>t', function()
    require('detour').Detour() -- Open a detour popup

    -- Switch to a blank buffer.
    -- This is a necessary precaution because the following call to telescope's
    -- `buffers` function may fail to bring up a prompt if it does not find any
    -- qualifying buffers. In that case, the call to `nvim_feedkeys` will
    -- write to this blank buffer instead of whatever buffer `Detour` opened
    -- with.
    vim.cmd.enew()

    vim.bo.bufhidden = 'delete'                 -- close the terminal when window closes
    require('telescope.builtin').buffers({})    -- Open telescope prompt
    vim.api.nvim_feedkeys("term://", "n", true) -- popuplate prompt with "term"
end)
```
||
|:--:|
| **Open two terminal buffers -> Use the keymap above -> Select desired terminal** |
| ![term](https://github.com/carbon-steel/detour.nvim/assets/7697639/775cd697-d47e-4d3c-9aaf-9f7f86c266f0) |


### Wrap a TUI: top
You can wrap any TUI in a popup. Here is an example.

Run `top` in a popup:
```lua
vim.keymap.set("n", '<leader>p', function ()
    require('detour').Detour()  -- open a detour popup
    vim.cmd.terminal('top')     -- open a terminal buffer
    vim.bo.bufhidden = 'delete' -- close the terminal when window closes

    -- It's common for people to have `<Esc>` mapped to `<C-\><C-n>` for terminals.
    -- This can get in the way when interacting with TUIs.
    -- This maps the escape key back to itself (for this buffer) to fix this problem.
    vim.keymap.set('t', '<Esc>', '<Esc>', { buffer = true })

    vim.cmd.startinsert() -- go into insert mode

    vim.api.nvim_create_autocmd({"TermClose"}, {
        buffer = vim.api.nvim_get_current_buf(),
        callback = function ()
            -- This automated keypress skips for you the "[Process exited 0]" message
            -- that the embedded terminal shows.
            vim.api.nvim_feedkeys('i', 'n', false)
        end
    })
end)
```

||
| :--: |
| **Use keymap above -> Close window** |
![top](https://github.com/carbon-steel/detour.nvim/assets/7697639/49dd12ab-630b-4558-9486-fe82cc94882c)

### Wrap a TUI: tig
Run `tig` in a popup:
```lua
vim.keymap.set('n', '<leader>g', function()
    local current_dir = vim.fn.expand("%:p:h")
    require('detour').Detour() -- open a detour popup

    -- Set this window's current working directory to current file's directory.
    -- tig finds a git repo based on the current working directory. 
    vim.cmd.lcd(current_dir)

    vim.cmd.terminal('tig')     -- open a terminal buffer running tig
    vim.bo.bufhidden = 'delete' -- close the terminal when window closes

    -- It's common for people to have `<Esc>` mapped to `<C-\><C-n>` for terminals.
    -- This can get in the way when interacting with TUIs.
    -- This maps the escape key back to itself (for this buffer) to fix this problem.
    vim.keymap.set('t', '<Esc>', '<Esc>', { buffer = true })

    vim.cmd.startinsert() -- go to insert mode

    vim.api.nvim_create_autocmd({"TermClose"}, {
        buffer = vim.api.nvim_get_current_buf(),
        callback = function ()
            -- This automated keypress skips for you the "[Process exited 0]" message
            -- that the embedded terminal shows.
            vim.api.nvim_feedkeys('i', 'n', false)
        end
    })
end)
```

||
|:--:|
| **Use keymap above -> Close window** |
| ![tig2](https://github.com/carbon-steel/detour.nvim/assets/7697639/7dd84b42-26d8-487b-8486-aa08e0fef5c8) |

# FAQ
> I want to convert popups to splits or tabs.

`<C-w>s` and `<C-w>v` can be used from within a popup to create splits. `<C-w>T` creates tabs.

> My LSP keeps moving my cursor to other windows.

If your LSP movements (ex: `go-to-definition`) are opening locations in other windows, make sure that you're not calling these movements with the `reuse_win` set to `true`.

> My popups don't look good.

Some colorschemes don't have visually clear floating window border colors. Consider customizing your colorscheme's FloatBorder to a color that makes your popups clearer.

