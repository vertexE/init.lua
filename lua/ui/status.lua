local M = {}

local splits = require("ui.splits")
local tbl = require("tbl")
local git_common = require("vcs.git_common")
local assistant = require("assistant.resources")

local STATUS_WIN_WIDTH = 30

local state = {
    bufnr = -1,
    winr = -1,
}

local diagnostic_icon_error = "✘"
local diagnostic_icon_warn = ""
local diagnostic_icon_info = "󰭺"
local diagnostic_icon_hint = ""

local diagnostic_hl_error = "DiagnosticError"
local diagnostic_hl_warn = "DiagnosticWarn"
local diagnostic_hl_info = "DiagnosticInfo"
local diagnostic_hl_hint = "DiagnosticHint"

local draw = function()
    vim.api.nvim_win_set_width(state.winr, STATUS_WIN_WIDTH)

    local ns = vim.api.nvim_create_namespace("user.status.window")
    local cursor_bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_clear_namespace(state.bufnr, ns, 0, -1)

    local v_lines = {}
    table.insert(v_lines, {
        {
            "╭───────────────────────────────────────────────────",
            "WinSeparator",
        },
    })

    local git_root = git_common.git_root()
    table.insert(v_lines, {
        { "│ ", "WinSeparator" },
        { "   ", "MiniIconsGreen" },
        { "editing ", "Comment" },
        { git_root, "MiniIconsOrange" },
    })

    table.insert(v_lines, {
        {
            "├─────────────────────────────────────────────",
            "WinSeparator",
        },
    })
    table.insert(v_lines, tbl.merge({ { "│ ", "WinSeparator" } }, assistant.agent()))

    for _, v_line in ipairs(assistant.status()) do
        table.insert(v_lines, tbl.merge({ { "│ ", "WinSeparator" } }, v_line))
    end

    table.insert(v_lines, {
        {
            "╰───────────────────────────────────────────────────",
            "WinSeparator",
        },
    })

    local error_cnt = #vim.diagnostic.get(cursor_bufnr, { severity = vim.diagnostic.severity.ERROR })
    local warn_cnt = #vim.diagnostic.get(cursor_bufnr, { severity = vim.diagnostic.severity.WARN })
    local info_cnt = #vim.diagnostic.get(cursor_bufnr, { severity = vim.diagnostic.severity.INFO })
    local hint_cnt = #vim.diagnostic.get(cursor_bufnr, { severity = vim.diagnostic.severity.HINT })
    local total = error_cnt + warn_cnt + info_cnt + hint_cnt

    table.insert(v_lines, {
        {
            "╭───────────────────────────────────────────────────",
            "WinSeparator",
        },
    })

    table.insert(v_lines, {
        { "│ ", "WinSeparator" },
        { total == 0 and " 󰄳  " or " ", "MiniIconsGreen" },
        { total == 0 and "- passing checks" or "", "Comment" },
        { error_cnt > 0 and string.format("%d %s ", error_cnt, diagnostic_icon_error) or "", diagnostic_hl_error },
        { warn_cnt > 0 and string.format("%d %s ", warn_cnt, diagnostic_icon_warn) or "", diagnostic_hl_warn },
        { info_cnt > 0 and string.format("%d %s ", info_cnt, diagnostic_icon_info) or "", diagnostic_hl_info },
        { hint_cnt > 0 and string.format("%d %s ", hint_cnt, diagnostic_icon_hint) or "", diagnostic_hl_hint },
    })

    table.insert(v_lines, {
        {
            "╰───────────────────────────────────────────────────",
            "WinSeparator",
        },
    })

    table.insert(v_lines, {
        {
            "╭───────────────────────────────────────────────────",
            "WinSeparator",
        },
    })

    table.insert(v_lines, {
        { "│ ", "WinSeparator" },
        { "󰫣 ", "MiniIconsGreen" },
        { " - llm requests", "Comment" },
    })

    table.insert(v_lines, {
        {
            "├───────────────────────────────────────────────────",
            "WinSeparator",
        },
    })

    local locked_files_vlines = assistant.locked_files()
    if #locked_files_vlines == 0 then
        table.insert(v_lines, { { "│ ", "WinSeparator" }, { "...", "Comment" } })
    else
        for _, v_line in ipairs(locked_files_vlines) do
            table.insert(v_lines, tbl.merge({ { "│ ", "WinSeparator" } }, v_line))
        end
    end

    table.insert(v_lines, {
        {
            "╰───────────────────────────────────────────────────",
            "WinSeparator",
        },
    })

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
        state.winr = -1
        return
    end

    local bufnr, winr = splits.vertical(nil, {
        wo = { number = false, statuscolumn = "" },
        bo = { buflisted = false },
        split = "left_most",
        width = STATUS_WIN_WIDTH,
    })
    state.bufnr = bufnr
    state.winr = winr

    vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "BufWrite", "DiagnosticChanged" }, {
        group = vim.api.nvim_create_augroup("user.status.window.draw", { clear = true }),
        callback = function()
            if state.bufnr > -1 and vim.api.nvim_buf_is_loaded(state.bufnr) then
                draw()
            end
        end,
    })

    vim.api.nvim_create_autocmd({ "TabEnter" }, {
        group = vim.api.nvim_create_augroup("user.status.tab.change", { clear = true }),
        callback = function()
            if M.is_open() then
                M.toggle_split()
                M.toggle_split()
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
