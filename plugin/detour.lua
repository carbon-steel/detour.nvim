local detour = require('detour')
vim.api.nvim_create_user_command("Detour", detour.Detour, {})
vim.api.nvim_create_user_command("DetourCurrentWindow", detour.DetourCurrentWindow, {})
