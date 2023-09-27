local M = {}

local function float(bufnr)
  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.9)

  local top = math.floor(((vim.o.lines - height) / 2) - 1)
  local left = math.floor((vim.o.columns - width) / 2)

  local win_opts = {
      relative = "editor",
      row = top,
      col = left,
      width = width,
      height = height,
      style = "minimal",
  }

  vim.api.nvim_open_win(bufnr, true, win_opts)
end

M.FloatWin = function ()
    float(vim.api.nvim_get_current_buf())
end

return M
