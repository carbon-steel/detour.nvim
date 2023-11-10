# detour.nvim
> It's a dangerous business, Frodo, going out your door. You step onto the road, and if you don't keep your feet, there's no knowing where you might be swept off to.

<div dir="rtl">
J.R.R. Tolkien, The Lord of the Rings 
</div>

# Never lose your spot!📍🗺️
`detour.nvim` provides the `:Detour` command that opens a popup window that you can use as you would a split window.

Popups are better than splits during those times when you want to take a detour into some other files without losing your place in the current file. They also allow you to use the entire screen whereas a split would not.

[Screencast from 2023-10-09 21-07-23.webm](https://github.com/carbon-steel/detour.nvim/assets/7697639/0326878b-d249-4d50-b7d1-193878f222d8)

# Installation

## Lazy.nvim

```lua
{ "carbon-steel/detour.nvim",
    config = function ()
       local detour = require("detour")
       -- The keymaps here are just an example. You should find keymaps that work better for you.
       vim.keymap.set('n', '<c-w><enter>', ":Detour<cr>")
   end
},
```

# FAQ
> I want to convert popups to splits or tabs.

`<C-w>s` and `<C-w>v` can be used from within a popup to create splits. `<C-w>T` creates tabs.

> My LSP keeps moving my cursor to other windows.

If your LSP movements (ex: `go-to-definition`) are opening locations in other windows, make sure that you're not calling these movements with the `reuse_win` set to `true`.

> My popups don't look good.

Some colorschemes don't have visually clear floating window border colors. Consider customizing your colorscheme's FloatBorder to a color that makes your popups clearer.

