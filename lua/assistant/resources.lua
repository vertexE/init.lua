local M = {}

local buf = require("buf")

local diagnostics = function(bufnr)
    local buf_name = vim.api.nvim_buf_get_name(bufnr or 0)
    local file_name = vim.fn.fnamemodify(buf_name, ":t")
    local diagnostics = vim.diagnostic.get(bufnr or 0)
    return vim.fn.join(
        vim.iter(diagnostics)
            :map(function(diagnostic)
                return string.format("%s:%d %s", file_name, diagnostic.lnum, diagnostic.message)
            end)
            :totable(),
        "\n"
    )
end

--- this really is only to track which resources are on/off, that's it!

--- @type table<resourceType,boolean>
local resources = {
    blocks = false,
    selection = false,
    git_diff = false,
    lsp_diagnostics = false,
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
        { " ", resources.blocks and "MiniIconsOrange" or "Comment" },
        { " - blocks", "Comment" },
    })
    return v_lines
end

local selection = function()
    local sel_start, sel_end = buf.active_selection()
    local lines = vim.api.nvim_buf_get_lines(0, sel_start - 1, sel_end, false)
    local ft = vim.api.nvim_get_option_value("filetype", { buf = 0 })
    return string.format("<active-selection filetype='%s'>", ft) .. table.concat(lines, "\n") .. "</active-selection>"
end

--- @alias resourceType "blocks"|"selection"|"lsp_diagnostics"|"git_diff"

---@param rt resourceType
M.toggle = function(rt)
    resources[rt] = not resources[rt]
end

local resource_state = {
    --- @type table<string>
    blocks = {},
}

--- all active resources
--- @param bufnr ?integer
--- @return string
M.active = function(bufnr)
    local knowledge = ""
    if resources.selection then
        knowledge = knowledge .. selection()
    end
    if resources.git_diff then
        knowledge = knowledge .. " #gitdiff:unstaged "
    end
    if resources.lsp_diagnostics then
        knowledge = knowledge .. "<diagnostics>" .. diagnostics(bufnr) .. "</diagnostics>"
    end
    if resources.blocks then
        knowledge = knowledge .. "<code-segments>" .. vim.fn.join(resource_state.blocks, "\n") .. "</code-segments>"
    end
    return knowledge
end

M.add_block = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local buf_name = vim.api.nvim_buf_get_name(bufnr)
    local file_name = vim.fn.fnamemodify(buf_name, ":t")
    local content = buf.active_selection_lines()
    table.insert(resource_state.blocks, string.format("<%s>\n%s\n</%s>", file_name, content, file_name))
    vim.notify("added block!", vim.log.levels.INFO, {})
end

M.clear_blocks = function()
    resource_state.blocks = {}
    vim.notify("clear blocks!", vim.log.levels.INFO, {})
end

return M
