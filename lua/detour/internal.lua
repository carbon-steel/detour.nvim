local M = {}

M.popup_to_covered_windows = {}

M.default_config = { keep_focus_on_top = false }
M.config = vim.tbl_deep_extend("force", {}, M.default_config) -- make a deep copy
M.user_config = {}

return M
