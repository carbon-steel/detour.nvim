# Display help files in a Detour window
Here are two examples of displaying help files in a Detour popup window without it
opening a split window.

### Creating a User Command
Opening a help file via a custom user command
```lua
vim.api.nvim_create_user_command("H", function (args)
    local file = args.args
    vim.cmd.h(file)
    local help_win = vim.api.nvim_get_current_win()

    local ok = require('detour').Detour()
    if ok then
        vim.api.nvim_win_close(help_win, false)
    end
end, { nargs = 1 })
```
> Note: The downside to a custom User Command is that you do not get the autocomplete
>       you would get with `:h` if you have nvim-cmp setup

### Creating an Auto Command
Opening a help file via `autocmd`
```lua
vim.api.nvim_create_autocmd("BufWinEnter", {
    pattern = "*",
    callback = function(event)
        local filetype = vim.bo[event.buf].filetype
        local file_path = event.match

        if file_path:match "/doc/" ~= nil then
            -- Only run if the filetype is a help file
            if filetype == "help" or filetype == "markdown" then
                -- Get the newly opened help window
                -- and attempt to open a Detour() float
                local help_win = vim.api.nvim_get_current_win()
                local ok = require("detour").Detour()

                -- If we successfully create a float of the help file
                -- Close the split
                if ok then
                    vim.api.nvim_win_close(help_win, false)
                end
            end
        end
    end,
})
```
> Note: This allows you to use `:h` and still get the autocompletion for docs
>       if you have nvim-cmp setup.
