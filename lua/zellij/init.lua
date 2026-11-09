local zellij = require("zellij.zellij")
local attention = require("zellij.notify")
local ui = require("zellij.ui")

local M = {}
local terminal
local busy = false
local notification_opts
local other_clients = "Close other clients attached to " .. zellij.session_name() .. " before picking a tab"

local function warn(message)
    vim.notify(message, vim.log.levels.WARN, { title = "Zellij" })
end

local function spawn_terminal()
    local Terminal = require("toggleterm.terminal").Terminal
    terminal = Terminal:new({
        -- ToggleTerm takes a shell command. Session name is a fixed literal.
        cmd = "exec zellij attach --create nvim-mux",
        direction = "tab",
        display_name = zellij.session_name(),
        hidden = true,
        close_on_exit = true,
        on_create = function(term)
            vim.keymap.set({ "n", "t" }, "<C-q>", function()
                term:close()
            end, { buffer = term.bufnr, desc = "Hide Zellij terminal" })
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
        return "Could not start Zellij in ToggleTerm" .. (err and (": " .. tostring(err)) or "")
    end
end

local function wait_for_client(term, callback)
    local deadline = vim.uv.now() + 5000
    local function check()
        if terminal ~= term then
            callback(nil, "Zellij exited while attaching to " .. zellij.session_name())
            return
        end
        zellij.clients(function(clients, err)
            if terminal ~= term then
                callback(nil, "Zellij exited while attaching to " .. zellij.session_name())
            elseif clients and #clients == 1 then
                callback(term, nil, clients[1])
            elseif clients and #clients > 1 then
                callback(nil, other_clients)
            elseif vim.uv.now() >= deadline then
                callback(nil, err and err.message or ("Timed out attaching to " .. zellij.session_name()))
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
    zellij.check_version(function(err)
        if err then
            callback(nil, err.message)
            return
        end
        zellij.clients(function(clients)
            if clients and #clients > 0 then
                callback(nil, other_clients)
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

local function focus_tab(tab, focused_pane, callback)
    local target = "terminal_" .. tab.pane_id
    if focused_pane == target then
        callback()
        return
    end
    zellij.focus_pane(tab.pane_id, function(err)
        if err then
            callback(err.message)
            return
        end
        zellij.clients(function(clients, client_err)
            if client_err then
                callback(client_err.message)
            elseif #clients ~= 1 then
                callback("Zellij focus requires one client attached to " .. zellij.session_name())
            elseif clients[1] == target then
                callback()
            else
                -- Until a client sends its first key, focus-pane-id can route to the CLI
                -- client. go-to-tab-by-id falls back to the attached client.
                zellij.focus_tab(tab.tab_id, function(tab_err)
                    if tab_err then
                        callback(tab_err.message)
                        return
                    end
                    zellij.clients(function(updated, verify_err)
                        if verify_err then
                            callback(verify_err.message)
                        elseif #updated == 1 and updated[1] == target then
                            callback()
                        else
                            callback("Zellij could not focus the selected pane. Press a key in Zellij and pick again.")
                        end
                    end)
                end)
            end
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
        focus_tab(tab, focused_pane, function(focus_err)
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
        zellij.tabs(function(tabs, query_err)
            busy = false
            if query_err then
                warn(query_err.message)
                return
            end
            attention.start(notification_opts)
            ui.pick(tabs, on_select)
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
        group = vim.api.nvim_create_augroup("user.zellij", { clear = true }),
        callback = function()
            attention.stop()
            if terminal then
                vim.fn.jobstop(terminal.job_id)
            end
        end,
    })
end

return M
