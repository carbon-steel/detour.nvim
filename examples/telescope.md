# Telescope keymaps
Here are examples of useful keymaps where you use detour popups together with the [telescope plugin](https://github.com/nvim-telescope/telescope.nvim).

### Terminal selection
Select an existing terminal to open in a popup. If none exist, open a new one. 
```lua
vim.keymap.set('n', '<leader>t', function()
    local terminal_buffer_found = false
    -- Check if we there are any existing terminal buffers.
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do -- iterate through all buffers
        if vim.api.nvim_buf_is_loaded(buf) then       -- only check loaded buffers
            if vim.api.nvim_buf_get_option(buf, "buftype") == "terminal" then
                terminal_buffer_found = true
            end
        end
    end

    require('detour').Detour()                      -- Open a detour popup
    if terminal_buffer_found then
        require('telescope.builtin').buffers({})    -- Open telescope prompt
        vim.api.nvim_feedkeys("term://", "n", true) -- populate prompt with "term://"
    else
        -- [OPTIONAL] Set the new window's current working directory to the directory of current file.
        -- You can remove this line if you would prefer to open terminals from the
        -- existing working directory.
        vim.cmd.lcd(vim.fn.expand("%:p:h"))
        -- Since there are no existing terminal buffers, open a new one.
        vim.cmd.terminal()
        vim.cmd.startinsert()
    end
end)
```
