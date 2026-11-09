local attention = require("plex.notify")
local panes = require("plex.panes")
local ui = require("plex.ui")

local M = {}
local strategy
local terminal
local busy = false
local notification_opts

local function other_clients()
    return "Close other clients attached to " .. strategy.session_name() .. " before picking a tab"
end

local function warn(message)
    vim.notify(message, vim.log.levels.WARN, { title = "Plex" })
end

local function spawn_terminal()
    local Terminal = require("toggleterm.terminal").Terminal
    terminal = Terminal:new({
        cmd = strategy.attach_command(),
        direction = "tab",
        display_name = strategy.session_name(),
        hidden = true,
        close_on_exit = true,
        on_create = function(term)
            vim.keymap.set({ "n", "t" }, "<C-q>", function()
                term:close()
            end, { buffer = term.bufnr, desc = "Hide Plex terminal" })
        end,
        on_exit = function(term)
            if terminal == term then
                terminal = nil
            end
        end,
    })
    local ok, err = pcall(terminal.spawn, terminal)
    if not ok or not terminal.job_id or terminal.job_id <= 0 then
        terminal = nil
        return "Could not start " .. strategy.name .. " in ToggleTerm" .. (err and (": " .. tostring(err)) or "")
    end
end

local function wait_for_client(term, callback)
    local deadline = vim.uv.now() + 5000
    local function check()
        if terminal ~= term then
            callback(nil, strategy.name .. " exited while attaching to " .. strategy.session_name())
            return
        end
        strategy.clients(function(clients, err)
            if terminal ~= term then
                callback(nil, strategy.name .. " exited while attaching to " .. strategy.session_name())
            elseif clients and #clients == 1 then
                callback(term, nil, clients[1])
            elseif clients and #clients > 1 then
                callback(nil, other_clients())
            elseif vim.uv.now() >= deadline then
                callback(nil, err and err.message or ("Timed out attaching to " .. strategy.session_name()))
            else
                vim.defer_fn(check, 100)
            end
        end)
    end
    check()
end

local function ensure_terminal(callback)
    if terminal then
        wait_for_client(terminal, callback)
        return
    end
    strategy.check_version(function(err)
        if err then
            callback(nil, err.message)
            return
        end
        strategy.clients(function(clients)
            if clients and #clients > 0 then
                callback(nil, other_clients())
                return
            end
            local spawn_err = spawn_terminal()
            if spawn_err then
                callback(nil, spawn_err)
                return
            end
            wait_for_client(terminal, callback)
        end)
    end)
end

function M.open_tab(tab)
    if busy then
        return
    end
    busy = true
    ensure_terminal(function(term, err, focused_pane)
        if not term then
            busy = false
            warn(err)
            return
        end
        if term:is_open() then
            term:focus()
        else
            term:open()
        end
        strategy.focus(tab, focused_pane, function(focus_err)
            busy = false
            if focus_err then
                warn(focus_err)
            end
            if terminal == term and term:is_open() and term:is_focused() then
                vim.cmd.startinsert()
            end
        end)
    end)
end

function M.pick(on_select, opts)
    if busy then
        return
    end
    busy = true
    local function show_picker()
        panes.tabs(strategy, function(tabs, query_err)
            busy = false
            if query_err then
                warn(query_err.message)
                return
            end
            attention.start(strategy, notification_opts)
            ui.pick(tabs, on_select, strategy)
        end)
    end
    if opts and opts.attach then
        ensure_terminal(function(term, err)
            if not term then
                busy = false
                warn(err)
                return
            end
            show_picker()
        end)
    else
        show_picker()
    end
end

function M.setup(opts)
    local name = opts and opts.strategy or "zellij"
    assert(name == "zellij" or name == "tmux", "Unknown Plex strategy: " .. tostring(name))
    local selected = require("plex." .. name)
    assert(not strategy or strategy == selected, "Plex strategy cannot change after setup")
    strategy = selected
    require("toggleterm").setup({
        shade_terminals = false,
        float_opts = { border = "rounded" },
        highlights = {
            FloatBorder = { link = "FloatBorder" },
        },
    })
    notification_opts = vim.tbl_extend("force", opts or {}, {
        is_terminal_focused = function()
            return terminal ~= nil and terminal:is_open() and terminal:is_focused()
        end,
    })
    vim.api.nvim_create_autocmd("VimLeavePre", {
        group = vim.api.nvim_create_augroup("user.plex", { clear = true }),
        callback = function()
            attention.stop()
            if strategy.stop then
                strategy.stop()
            end
            if terminal then
                vim.fn.jobstop(terminal.job_id)
            end
        end,
    })
end

return M
