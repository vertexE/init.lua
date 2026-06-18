local M = {}

local splits = require("ui.splits")
local tbl = require("tbl")
local assistant = require("assistant.resources")
local agents = require("assistant.agents")
local symbols = require("symbols")

local animation_frame_index = 1
local frames = symbols.braille_spinner_frames

local STATUS_WIN_WIDTH = 30

local state = {
    bufnr = -1,
    winr = -1,
    -- whether the draw loop is running
    is_draw_loop_running = false,
}

local draw = function()
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
            "├─────────────────────────────────────────────",
            "WinSeparator",
        },
    })
    table.insert(v_lines, { { "│ ", "WinSeparator" }, { " 󰫣  context", "MiniIconsOrange" } })

    for _, v_line in ipairs(assistant.status()) do
        table.insert(v_lines, tbl.merge({ { "│ ", "WinSeparator" } }, v_line))
    end

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
        { "  ", "MiniIconsGreen" },
        { " - locked files", "Comment" },
    })

    table.insert(v_lines, {
        {
            "├───────────────────────────────────────────────────",
            "WinSeparator",
        },
    })

    local locked_files_vlines = assistant.locked_files()
    if #locked_files_vlines == 0 then
        table.insert(v_lines, { { "│ ", "WinSeparator" } })
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

    table.insert(v_lines, {
        {
            "╭───────────────────────────────────────────────────",
            "WinSeparator",
        },
    })

    local agent_sessions = agents.list_agents("ACTIVE")
    if #agent_sessions > 0 then
        table.insert(v_lines, {
            { "│ ", "WinSeparator" },
            { string.format(" %s ", frames[animation_frame_index % #frames + 1]), "MiniIconsGreen" },
            {
                #agent_sessions == 1 and " - 1 session active" or string.format("%d sessions active", #agent_sessions),
                "Comment",
            },
        })
        animation_frame_index = animation_frame_index + 1
    else
        table.insert(v_lines, {
            { "│ ", "WinSeparator" },
            { " 󰫣 ", "MiniIconsGreen" },
            { " - 0 sessions active", "Comment" },
        })
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

local should_run_draw_loop = function()
    return #agents.list_agents("ACTIVE") > 0 and M.is_open()
end

local draw_loop = function()
    if state.is_draw_loop_running then
        --- ensure we only have 1 draw_loop
        return
    end

    state.is_draw_loop_running = true

    local timer = vim.loop.new_timer()
    if not timer then
        state.is_draw_loop_running = false
        vim.notify("ui.status: failed to create draw_loop timer", vim.log.levels.ERROR)
        return
    end

    timer:start(
        0,
        100,
        vim.schedule_wrap(function()
            if not should_run_draw_loop() then
                timer:stop()
                timer:close()
                state.is_draw_loop_running = false
                if M.is_open() then
                    draw()
                end
                return
            end
            draw()
        end)
    )
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

    vim.api.nvim_create_autocmd({ "User" }, {
        pattern = "AgentStatusChange",
        group = vim.api.nvim_create_augroup("user.status.agents", { clear = true }),
        callback = function()
            if state.bufnr > -1 and vim.api.nvim_buf_is_loaded(state.bufnr) then
                -- draw loop for agent status changes
                draw_loop()
            end
        end,
    })

    draw()
end

return M
