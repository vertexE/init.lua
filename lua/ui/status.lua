local M = {}

local splits = require("ui.splits")
local tbl = require("tbl")
local git_common = require("vcs.git_common")
local assistant = require("assistant.resources")

local MAX_DIAGNOSTICS = 15

-- TODO: need to extract these and statusline out to ui module
local diagnostic_icon = {
    [vim.diagnostic.severity.ERROR] = "✘",
    [vim.diagnostic.severity.WARN] = "",
    [vim.diagnostic.severity.INFO] = "󰭺",
    [vim.diagnostic.severity.HINT] = "",
}

local diagnostic_hl = {
    [vim.diagnostic.severity.ERROR] = "DiagnosticError",
    [vim.diagnostic.severity.WARN] = "DiagnosticWarn",
    [vim.diagnostic.severity.INFO] = "DiagnosticInfo",
    [vim.diagnostic.severity.HINT] = "DiagnosticHint",
}

local state = {
    bufnr = -1,
}

local draw = function()
    local ns = vim.api.nvim_create_namespace("user.status.window")
    vim.api.nvim_buf_clear_namespace(state.bufnr, ns, 0, -1)

    local cursor_bufnr = vim.api.nvim_get_current_buf()
    local v_lines = {}
    table.insert(v_lines, {
        { "  ", "MiniIconsGreen" },
        { "editing ", "Comment" },
        { git_common.git_root(), "@constant" },
    })
    local diagnostics = tbl.slice(vim.diagnostic.get(cursor_bufnr), 1, MAX_DIAGNOSTICS)
    local icon = #diagnostics == 0 and "  " or "  "
    local hl = #diagnostics == 0 and "MiniIconsGreen" or "MiniIconsOrange"
    table.insert(v_lines, {
        { icon, hl },
        { "diagnostics", "@constant" },
    })

    table.insert(v_lines, {
        {
            string.rep("∵∴∵∴∵∴∵∴∵∴∵∴∵∴∵∴∵∴∵∴∵∴", 4),
            "Comment",
        },
    })
    for _, diagnostic in ipairs(diagnostics) do
        local _icon = diagnostic_icon[diagnostic.severity]
        local _hl = diagnostic_hl[diagnostic.severity]
        table.insert(v_lines, {
            { _icon, _hl },
            { string.format(" %d:%d ", diagnostic.lnum, diagnostic.col), "Comment" },
            { diagnostic.message, _hl },
        })
    end
    for _ = #diagnostics, MAX_DIAGNOSTICS do
        -- reserve space for diagnostics
        table.insert(v_lines, {})
    end
    table.insert(v_lines, {
        {
            string.rep("∵∴∵∴∵∴∵∴∵∴∵∴∵∴∵∴∵∴∵∴∵∴", 4),
            "Comment",
        },
    })
    table.insert(v_lines, {
        { "󰫢  ", "MiniIconsGreen" },
        { "Agent ", "Comment" },
    })

    local assistant_v_lines = assistant.status()
    for _, v_line in ipairs(assistant_v_lines) do
        table.insert(v_lines, v_line)
    end

    local v_line = v_lines[1]
    local remaining = { unpack(v_lines, 2) }
    vim.api.nvim_buf_set_extmark(state.bufnr, ns, 0, 0, {
        virt_text = v_line,
        virt_lines = remaining,
        virt_text_pos = "overlay",
    })
end

M.is_open = function()
    return state.bufnr > -1
end

M.toggle_split = function()
    if state.bufnr > -1 then
        vim.api.nvim_buf_delete(state.bufnr, { force = true })
        state.bufnr = -1
        return
    end

    local bufnr = splits.vertical(nil, {
        wo = { number = false },
        bo = { buflisted = false },
        split = "left",
        width = 30,
    })
    state.bufnr = bufnr

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWrite", "DiagnosticChanged" }, {
        group = vim.api.nvim_create_augroup("user.status.window.draw", { clear = true }),
        callback = function()
            if state.bufnr > -1 and vim.api.nvim_buf_is_loaded(state.bufnr) then
                draw()
            end
        end,
    })

    vim.api.nvim_create_autocmd({ "User" }, {
        pattern = "StatusRedraw",
        group = vim.api.nvim_create_augroup("user.status.window.draw.force", { clear = true }),
        callback = function()
            if state.bufnr > -1 and vim.api.nvim_buf_is_loaded(state.bufnr) then
                draw()
            end
        end,
    })
    draw()
end

return M
