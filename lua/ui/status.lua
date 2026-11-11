local M = {}

local splits = require("ui.splits")

local STATUS_WIN_WIDTH = 30

local state = {
    bufnr = -1,
    winr = -1,
    -- whether the draw loop is running
    is_draw_loop_running = false,
}

local draw = function()
    -- TODO: swap to set win config instead
    vim.api.nvim_win_set_width(state.winr, STATUS_WIN_WIDTH)

    local ns = vim.api.nvim_create_namespace("user.status.window")
    vim.api.nvim_buf_clear_namespace(state.bufnr, ns, 0, -1)

    local v_lines = {}
    table.insert(v_lines, {
        {
            "╭───────────────────────────────────────────────────",
            "WinSeparator",
        },
    })

    table.insert(v_lines, {
        { "│ ", "WinSeparator" },
        { "   ", "MiniIconsGreen" },
        { "editing ", "Comment" },
        { vim.fn.fnamemodify(vim.fn.getcwd(), ":t"), "MiniIconsOrange" },
    })

    table.insert(v_lines, {
        {
            "╰─────────────────────────────────────────────",
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
        wo = { number = false, relativenumber = false, statuscolumn = "" },
        bo = { buflisted = false },
        split = "left_most",
        width = STATUS_WIN_WIDTH,
        on_close = function()
            state.bufnr = -1
            state.winr = -1
        end,
    })
    state.bufnr = bufnr
    state.winr = winr

    vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "BufWrite", "DiagnosticChanged" }, {
        group = vim.api.nvim_create_augroup("user.status.window.draw", { clear = true }),
        callback = function()
            if vim.api.nvim_get_current_win() == state.winr then
                -- move out of the window if we can
                local keys = vim.api.nvim_replace_termcodes("<C-w>l", true, false, true)
                vim.api.nvim_feedkeys(keys, "n", false)
            end

            if
                state.bufnr > -1
                and vim.api.nvim_buf_is_loaded(state.bufnr)
                and vim.api.nvim_win_is_valid(state.winr)
            then
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
