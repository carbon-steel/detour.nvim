local detour = require("detour")
local features = require("detour.features")

vim.api.nvim_create_user_command("Detour", detour.Detour, {})

vim.api.nvim_create_user_command(
	"DetourCurrentWindow",
	detour.DetourCurrentWindow,
	{}
)

vim.api.nvim_create_user_command(
	"DetourUncoverWindowWithMouse",
	features.UncoverWindowWithMouse,
	{}
)

vim.api.nvim_create_user_command(
	"DetourHideAllDetours",
	features.HideAllDetours,
	{}
)

vim.api.nvim_create_user_command(
	"DetourRevealAllDetours",
	features.RevealAllDetours,
	{}
)

vim.api.nvim_create_user_command(
	"DetourCloseCurrentStack",
	features.CloseCurrentStack,
	{}
)
