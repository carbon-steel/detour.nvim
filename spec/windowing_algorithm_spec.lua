local algo = require("detour.windowing_algorithm")
local util = require("detour.util")

describe("detour windowing_algorithm", function()
  before_each(function()
    vim.g.detour_testing = true
    vim.cmd([[ 
      %bwipeout!
      mapclear
      nmapclear
      vmapclear
      xmapclear
      smapclear
      omapclear
      mapclear
      imapclear
      lmapclear
      cmapclear
      tmapclear
    ]])
    vim.api.nvim_clear_autocmds({})
    vim.o.splitbelow = true
    vim.o.splitright = true
  end)

  it("construct_nest returns inner rectangle inside parent float", function()
    -- create a parent float with known geometry and no border
    local parent = vim.api.nvim_open_win(vim.api.nvim_get_current_buf(), true, {
      relative = "editor",
      row = 5,
      col = 10,
      width = 30,
      height = 10,
      border = "none",
      zindex = 1,
    })
    assert.truthy(parent)

    local top, bottom, left, right = util.get_text_area_dimensions(parent)
    local expected_width = (right - left)
    local expected_height = (bottom - top)
    if expected_height >= 3 then
      expected_height = expected_height - 2
      top = top + 1
    end
    if expected_width >= 3 then
      expected_width = expected_width - 2
      left = left + 1
    end

    local opts = algo.construct_nest(parent, 2)
    assert.same({
      relative = "editor",
      row = top,
      col = left,
      width = expected_width,
      height = expected_height,
      border = "rounded",
      zindex = 2,
    }, opts)
  end)
end)

