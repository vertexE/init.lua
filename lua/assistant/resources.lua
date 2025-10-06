local M = {}

--- this really is only to track which resources are on/off, that's it!
local resources = {
    blocks = false,
    selection = false,
    git_diff = false,
    lsp_diagnostics = false,
}

--- all active resources
--- @return string
M.active = function()
    return "#buffers:listed #diagnostics:current"
end

return M
