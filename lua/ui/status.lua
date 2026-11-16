local M = {}

local plex = require("plex")
local plex_ui = require("plex.ui")
local splits = require("ui.splits")
local pulse_frames = { "·", "•", "●", "•" }

local STATUS_WIN_WIDTH = 30

local state = {
    bufnr = -1,
    winr = -1,
    terminal_rows = {},
}

local draw = function()
    -- TODO: swap to set win config instead
    if vim.api.nvim_win_get_width(state.winr) ~= STATUS_WIN_WIDTH then
        vim.api.nvim_win_set_width(state.winr, STATUS_WIN_WIDTH)
    end

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

    vim.list_extend(v_lines, state.terminal_rows)

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
        return
    end

    local bufnr, winr = splits.vertical(nil, {
        wo = { number = false, relativenumber = false, statuscolumn = "" },
        bo = { buflisted = false, bufhidden = "wipe" },
        split = "left_most",
        width = STATUS_WIN_WIDTH,
    })
    state.bufnr = bufnr
    state.winr = winr

    local frame = 1
    local spinners = {}
    local timer = assert(vim.uv.new_timer())
    local animate = vim.schedule_wrap(function()
        if timer:is_closing() or #spinners == 0 or not vim.api.nvim_win_is_valid(winr) then
            return
        end
        frame = frame % #pulse_frames + 1
        for _, chunk in ipairs(spinners) do
            chunk[1] = pulse_frames[frame]
        end
        draw()
    end)
    local unsubscribe = plex.subscribe_tabs(function(tabs)
        if not vim.api.nvim_win_is_valid(winr) then
            return
        end
        local rows, working = plex_ui.status_rows(tabs, pulse_frames[frame])
        spinners = working
        local changed = not vim.deep_equal(rows, state.terminal_rows)
        state.terminal_rows = rows
        if changed then
            draw()
        end
        if #spinners == 0 then
            timer:stop()
        elseif not timer:is_active() then
            timer:start(150, 150, animate)
        end
    end)
    vim.api.nvim_create_autocmd("BufWipeout", {
        buffer = bufnr,
        once = true,
        callback = function()
            timer:stop()
            timer:close()
            unsubscribe()
            state.bufnr = -1
            state.winr = -1
            state.terminal_rows = {}
        end,
    })

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
