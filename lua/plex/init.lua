local attention = require("plex.notify")
local panes = require("plex.panes")
local ui = require("plex.ui")

local M = {}
local strategy
local terminal
local busy = false
local notification_opts
local tabs = {}
local listeners = {}
local monitoring = false

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
    if busy or not tab then
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

local function start_monitor()
    if not strategy or monitoring then
        return
    end
    monitoring = true
    attention.subscribe(function(current, err)
        tabs = not err and panes.select_tabs(current or {}) or {}
        ui.update_bindings(tabs, M.open_tab)
        for callback in pairs(listeners) do
            callback(tabs)
        end
    end)
    attention.start(strategy, notification_opts)
end

function M.prepare()
    start_monitor()
    if not strategy or #tabs > 0 or busy then
        return
    end

    busy = true
    panes.tabs(strategy, function(_, query_err)
        if not query_err then
            busy = false
            return
        end
        ensure_terminal(function(_, err)
            busy = false
            if err then
                warn(err)
            end
        end)
    end)
end

function M.subscribe_tabs(callback)
    listeners[callback] = true
    start_monitor()
    callback(tabs)
    return function()
        listeners[callback] = nil
    end
end

function M.message()
    local tab = ui.choose_tab()
    if tab then
        require("plex.message").open(tab, strategy)
    end
end

local function new_tab(directory)
    local function create()
        strategy.new_tab(vim.fn.fnamemodify(directory, ":p"), function(err)
            if err then
                warn(err.message)
            end
        end)
    end
    strategy.panes(function(_, query_err)
        if not query_err then
            create()
            return
        end
        ensure_terminal(function(term, err)
            if not term then
                warn(err)
                return
            end
            create()
        end)
    end)
end

function M.tag_tab(tab)
    if not tab then
        return
    end
    require("snacks").input({ prompt = "Tag", default = tab.tab_tag or "" }, function(value)
        if value == nil then
            return
        end
        local tag = vim.trim(value:gsub("%c", " "))
        tag = tag ~= "" and tag or nil
        if tag ~= tab.tab_tag then
            strategy.set_tab_tag(tab.tab_id, tab.tab_name, tag, function(_, err)
                if err then
                    warn(err.message)
                end
            end)
        end
    end)
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
    vim.api.nvim_create_user_command("PlexNew", function()
        require("snacks").input({ prompt = "Directory", default = vim.fn.getcwd(), completion = "dir" }, function(directory)
            if directory and vim.trim(directory) ~= "" then
                new_tab(vim.fn.expand(directory))
            end
        end)
    end, {})
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
