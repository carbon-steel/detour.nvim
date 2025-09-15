---@mod detour.algorithm
---@tag detour-algorithm
---@brief [[
---Detour's windowing algorithm computes the largest rectangle where a
---floating window (detour) can be placed without overlapping windows that must
---remain visible.
---
---Overview
---
--- Each detour has a list of "reserved" windows that it is allowed to cover.
---
--- When creating or resizing a detour, the algorithm will find the largest
--- rectangular area where a floating window can go that covers only reserved
--- windows. That rectangle will be the position and dimensions of the detour.
---
--- `Detour()` creates a detour `d` where all windows that are not currently
--- reserved by an existing detour are reserved by `d`.
---
--- `DetourCurrentWindow()` creates a detour `d` where only the current window
--- is reserved by `d`.
---
---Resizing
---
--- Whenever windows open, close, or get resized, detours will recalculate the
--- largest area they can fill and dynamically reshape themselves. This allows
--- them to make room for new windows or to expand to take space that has been
--- freed up.
---@brief ]]
local algorithm_doc = {}

--- Internal anchor to ensure module docs render. Do not use.
---@private
function algorithm_doc._doc_anchor() end

return algorithm_doc
