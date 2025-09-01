local detour = require("detour")
local util = require("detour.util")
local features = require("detour.features")

local function Set(list)
  local set = {}
  for _, l in ipairs(list) do
    set[l] = true
  end
  return set
end

describe("detour uncover feature", function()
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
    vim.api.nvim_clear_autocmds({}) -- delete any autocmds not in a group
    for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ pattern = "*" })) do
      if vim.startswith(autocmd.group_name, "detour-") then
        vim.api.nvim_del_autocmd(autocmd.id)
      end
    end
    vim.o.splitbelow = true
    vim.o.splitright = true
  end)

  it("uncover one base window and resize popup accordingly", function()
    -- Create a simple 2-column layout
    local left_base = vim.api.nvim_get_current_win()
    vim.cmd.vsplit()
    local right_base = vim.api.nvim_get_current_win()

    -- Create a detour covering both base windows
    local popup = assert(detour.Detour())

    -- Sanity: popup overlaps both bases initially
    assert.True(util.overlap(popup, left_base))
    assert.True(util.overlap(popup, right_base))

    -- Uncover the left base window
    assert.True(features.UncoverWindow(left_base))

    -- The popup should no longer overlap the left base
    assert.False(util.overlap(popup, left_base))
    -- The popup should still overlap the right base
    assert.True(util.overlap(popup, right_base))

    -- Covered windows should only include the right base now
    local covered = Set(util.find_covered_windows(popup))
    assert.True(covered[right_base])
    assert.is_nil(covered[left_base])
  end)

  it("prevent uncovering the last remaining base window", function()
    -- Create a simple 2-column layout
    local left_base = vim.api.nvim_get_current_win()
    vim.cmd.vsplit()
    local right_base = vim.api.nvim_get_current_win()

    -- Create a detour covering both base windows
    local popup = assert(detour.Detour())

    -- Uncover one window first
    assert.True(features.UncoverWindow(left_base))

    -- Attempt to uncover the last remaining window should fail
    assert.False(features.UncoverWindow(right_base))

    -- State should remain unchanged: popup still overlaps right_base
    assert.True(util.overlap(popup, right_base))
    assert.False(util.overlap(popup, left_base))
  end)
end)

