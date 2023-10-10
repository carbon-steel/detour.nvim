# detour.nvim
> It's a dangerous business, Frodo, going out your door. You step onto the road, and if you don't keep your feet, there's no knowing where you might be swept off to.

<div dir="rtl">
J.R.R. Tolkien, The Lord of the Rings 
</div>

# Never lose your spot!📍🗺️
[Screencast from 2023-10-09 20-48-04.webm](https://github.com/carbon-steel/detour.nvim/assets/7697639/d70f7b4c-207a-423d-b332-7c89d9db1ea8)

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
