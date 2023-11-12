# detour.nvim
> It's a dangerous business, Frodo, going out your door. You step onto the road, and if you don't keep your feet, there's no knowing where you might be swept off to.

<div dir="rtl">
J.R.R. Tolkien, The Lord of the Rings 
</div>

![detour](https://github.com/carbon-steel/detour.nvim/assets/7697639/63a88fd3-f910-4e42-9664-0e14fe88d066)

# Never lose your spot!📍🗺️
`detour.nvim` provides the `:Detour` command that opens a popup window that you can use as you would a split window.

`detour.nvim` has two uses:
* Use popups instead of splits
    * Popups are better than splits during those times when you want to take a detour into some other files without losing your place in the current file.
    * They also allow you to use the entire screen whereas a split would not.
* Provide a large popup windows for TUIs, scripts, and commands.
    * This feature is similar to what `toggleterm.nvim` and `lazygit.nvim` do for you.

| ![basic](https://github.com/carbon-steel/detour.nvim/assets/7697639/3a408a14-8b9d-4bd4-90db-e633c5f97b7c) |
|:--:| 
| *Open a popup -> Go to different file -> Create vertical split -> Close popup* |

# Installation

## Lazy.nvim

```lua
{ "carbon-steel/detour.nvim",
    config = function ()
       vim.keymap.set('n', '<c-w><enter>', ":Detour<cr>")
   end
},
```

# Recipes
`detour.nvim` is capable of more than just reading files. It generalizes the floating window behavior of plugins such as toggleterm.nvim or lazygit.nvim. `detour.nvim` can wrap any TUI in a floating window. Its applications don't stop at just TUIs. You can use `Detour()` with any lua code.

Here are some examples:

</br>

### Terminal management

```lua
-- A keymap for opening a prompt to select a terminal buffer to open in a popup
vim.keymap.set('n', '<leader>t', function()
    require('detour').Detour()               -- Open a detour popup

    -- Switch to a blank buffer to prevent any accidental changes.
    vim.cmd.enew()
    vim.bo.bufhidden = 'delete'

    require('telescope.builtin').buffers({}) -- Open telescope prompt
    vim.api.nvim_feedkeys("term", "n", true) -- popuplate prompt with "term"
end)
```
| ![term](https://github.com/carbon-steel/detour.nvim/assets/7697639/775cd697-d47e-4d3c-9aaf-9f7f86c266f0) |
|:--:|
| *Open two terminal buffers -> Use the keymap above -> Select desired terminal* |

### Git TUI

```lua
-- A keymap for running tig in a popup
vim.keymap.set('n', '<leader>g', function()
    local current_path = vim.fn.expand("%:p:h")
    local command = "a".. -- go into terminal mode
                "cd ".. current_path .. "<CR>" ..
                "tig<CR>" -- run tig
    command = vim.api.nvim_replace_termcodes(command, true, false, true)

    require('detour').Detour()  -- open a detour popup
    vim.cmd.terminal()          -- open a terminal buffer
    vim.bo.bufhidden = 'delete' -- close the terminal when window closes
    vim.api.nvim_feedkeys(command, "n", false)
end)
```
| ![tig2](https://github.com/carbon-steel/detour.nvim/assets/7697639/7dd84b42-26d8-487b-8486-aa08e0fef5c8) |
|:--:|
| *Use keymap above -> Close tig* |

### top
```lua
-- Wrap any TUI inside a popup
vim.keymap.set("n", '<leader>p', function ()
    require('detour').Detour()  -- open a detour popup
    vim.cmd.terminal()          -- open a terminal buffer
    vim.bo.bufhidden = 'delete' -- close the terminal when window closes
    -- Run the `top` command
    local text = vim.api.nvim_replace_termcodes("atop<CR>", true, false, true)
    vim.api.nvim_feedkeys(text, "n", false)
end)

```
![top](https://github.com/carbon-steel/detour.nvim/assets/7697639/49dd12ab-630b-4558-9486-fe82cc94882c)



# FAQ
> I want to convert popups to splits or tabs.

`<C-w>s` and `<C-w>v` can be used from within a popup to create splits. `<C-w>T` creates tabs.

> My LSP keeps moving my cursor to other windows.

If your LSP movements (ex: `go-to-definition`) are opening locations in other windows, make sure that you're not calling these movements with the `reuse_win` set to `true`.

> My popups don't look good.

Some colorschemes don't have visually clear floating window border colors. Consider customizing your colorscheme's FloatBorder to a color that makes your popups clearer.

