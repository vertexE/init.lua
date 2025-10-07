local M = {}

local buf = require("buf")

--- this really is only to track which resources are on/off, that's it!

--- @type table<resourceType,boolean>
local resources = {
    selection = false,
    git_diff = false,
    lsp_diagnostics = false,
    current_buf = false,
    buffers_listed = false,
}

M.status = function()
    local v_lines = {}
    table.insert(v_lines, {
        { "󰒉 ", resources.selection and "MiniIconsOrange" or "Comment" },
        { " - visual lines", "Comment" },
    })
    table.insert(v_lines, {
        { " ", resources.lsp_diagnostics and "MiniIconsOrange" or "Comment" },
        { " - diagnostics", "Comment" },
    })
    table.insert(v_lines, {
        { " ", resources.git_diff and "MiniIconsOrange" or "Comment" },
        { " - git diff (unstaged)", "Comment" },
    })
    table.insert(v_lines, {
        { " ", resources.buffers_listed and "MiniIconsOrange" or "Comment" },
        { " - listed buffers", "Comment" },
    })
    return v_lines
end

local selection = function()
    local sel_start, sel_end = buf.active_selection()
    local lines = vim.api.nvim_buf_get_lines(0, sel_start - 1, sel_end, false)
    local ft = vim.api.nvim_get_option_value("filetype", { buf = 0 })
    return string.format("<active-selection filetype='%s'>", ft) .. table.concat(lines, "\n") .. "</active-selection>"
end

--- @alias resourceType "selection"|"lsp_diagnostics"|"git_diff"|"buffers_listed"|"current_buf"

---@param rt resourceType
M.toggle = function(rt)
    resources[rt] = not resources[rt]
    vim.print(resources)
end

--- all active resources
--- @return string
M.active = function()
    local knowledge = ""
    if resources.selection then
        knowledge = knowledge .. selection()
    end
    if resources.git_diff then
        knowledge = knowledge .. " #gitdiff:unstaged "
    end
    if resources.lsp_diagnostics then
        knowledge = knowledge .. " #diagnostics:current "
    end
    if resources.buffers_listed then
        knowledge = knowledge .. " #buffers:listed "
    end
    return knowledge
end

return M
