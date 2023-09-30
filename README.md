# detour.nvim
> It's a dangerous business, Frodo, going out your door. You step onto the road, and if you don't keep your feet, there's no knowing where you might be swept off to.

<div dir="rtl">
J.R.R. Tolkien, The Lord of the Rings 
</div>

# Never lose your spot!📍🗺️
The programming process always includes interruptions where we stop writing code and go read some other code. This Neovim plugin helps us find our way back from these detours.

(Neo)Vim users often encapsulate detours in a split or a tab. However,
* Splits "split" your screen's space (especially bad if you're only reading from one of the splits).
* We're not always good about cleaning up splits/tabs (cluttering up your workspace).

What if we used a popup window instead?

# How to use
## Typical Use
`detour.nvim` allows you to open a popup window containing your current buffer. You can treat that popup window as you would a new split or tab. That means you can switch to other files and locations. When you want to come back to where you started, just close the window.

[Screencast from 2023-09-30 10-16-12.webm](https://github.com/carbon-steel/detour.nvim/assets/7697639/8ebef6a8-c125-497f-83a0-82546ae2ac28)

## Promote to a split
You can "promote" your popup to be a split (vertical or horizontal) if you want.

[Screencast from 2023-09-30 10-19-35.webm](https://github.com/carbon-steel/detour.nvim/assets/7697639/b7dac6ba-177e-494d-a79c-2a9c5c831db9)

## Promote to tab
You can "promote" your popup to be a tab as well.

[Screencast from 2023-09-30 10-18-35.webm](https://github.com/carbon-steel/detour.nvim/assets/7697639/2af0f027-97f0-450a-9db9-33341b6026f2)

# Installation
## Lazy.nvim
```lua
{ "carbon-steel/detour.nvim",
    config = function ()
       local detour = require("detour")
       -- The keymaps here are just an example. You should find keymaps that work better for you.
       vim.keymap.set('n', '<c-w><enter>', detour.FloatWin)
       vim.keymap.set('n', '<c-w>,', detour.PromoteToTab)
       vim.keymap.set('n', '<c-w>.', detour.PromoteToSplit)
       vim.keymap.set('n', '<c-w>/', detour.PromoteToVsplit)
   end
},
```
