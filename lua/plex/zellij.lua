local panes = require("plex.panes")

local M = { name = "Zellij" }

local session = "nvim-mux"

local function failure(kind, message)
    return { kind = kind, message = message }
end

function M.session_name()
    return session
end

function M.attach_command()
    return "exec zellij attach --create " .. session
end

local function run(args, label, callback)
    if vim.fn.executable("zellij") == 0 then
        callback(nil, failure("missing_binary", "zellij executable missing from PATH"))
        return
    end

    local command = vim.list_extend({ "zellij" }, args)
    local ok, process = pcall(vim.system, command, { text = true, timeout = 5000 }, vim.schedule_wrap(function(result)
        if result.code ~= 0 then
            local detail = vim.trim(result.stderr or "")
            local message = "Zellij " .. label .. " failed"
            if detail ~= "" then
                message = message .. ": " .. detail
            else
                message = message .. " (exit " .. result.code .. ")"
            end
            callback(nil, failure("command_failed", message))
            return
        end

        callback(result.stdout or "")
    end))
    if not ok then
        callback(nil, failure("command_failed", "Could not start zellij: " .. tostring(process)))
    end
end

local function action(args, callback)
    run(vim.list_extend({ "--session", session, "action" }, args), args[1] .. " for " .. session, callback)
end

function M.check_version(callback)
    run({ "--version" }, "version check", function(_, err)
        callback(err)
    end)
end

function M.clients(callback)
    action({ "list-clients" }, function(stdout, err)
        if err then
            callback(nil, err)
            return
        end
        local clients = {}
        for line in stdout:gmatch("[^\n]+") do
            local pane = line:match("^%s*%d+%s+(%S+)")
            if pane then
                clients[#clients + 1] = tonumber(pane:match("^terminal_(%d+)$")) or pane
            end
        end
        callback(clients)
    end)
end

function M.focus_pane(pane_id, callback)
    action({ "focus-pane-id", "terminal_" .. pane_id }, function(_, err)
        callback(err)
    end)
end

function M.focus_tab(tab_id, callback)
    action({ "go-to-tab-by-id", tostring(tab_id) }, function(_, err)
        callback(err)
    end)
end

function M.new_tab(cwd, callback)
    action({ "new-tab", "--cwd", cwd, "--no-focus" }, function(_, err)
        callback(err)
    end)
end

function M.set_tab_tag(tab_id, name, tag, callback)
    local title = panes.tagged_name(name, tag)
    action({ "rename-tab-by-id", "--", tostring(tab_id), title }, function(_, err)
        if err then
            callback(nil, err)
            return
        end
        action({ "save-session" }, function(_, save_err)
            callback(title, save_err)
        end)
    end)
end

local function nonempty_string(value)
    return type(value) == "string" and value ~= "" and value or nil
end

function M.panes(callback)
    action({ "list-panes", "--all", "--json" }, function(stdout, err)
        if err then
            callback(nil, err)
            return
        end

        local decoded, raw_panes = pcall(vim.json.decode, stdout)
        if not decoded or not vim.islist(raw_panes) then
            callback(nil, failure("invalid_json", "Zellij list-panes did not return a JSON array"))
            return
        end

        local records = {}
        for _, pane in ipairs(raw_panes) do
            if type(pane) ~= "table" or type(pane.is_plugin) ~= "boolean" then
                callback(nil, failure("invalid_json", "Zellij list-panes returned an invalid pane"))
                return
            end

            if not pane.is_plugin then
                if
                    type(pane.id) ~= "number"
                    or type(pane.tab_id) ~= "number"
                    or type(pane.tab_position) ~= "number"
                    or type(pane.is_focused) ~= "boolean"
                    or type(pane.is_floating) ~= "boolean"
                    or type(pane.is_selectable) ~= "boolean"
                    or type(pane.is_suppressed) ~= "boolean"
                    or type(pane.exited) ~= "boolean"
                then
                    callback(nil, failure("incompatible_version", "Zellij list-panes is missing required pane fields"))
                    return
                end

                if pane.is_selectable and not pane.is_suppressed and not pane.exited then
                    local name = nonempty_string(pane.tab_name) or ("Tab #" .. (pane.tab_position + 1))
                    local tag, title = panes.split_tab_name(name)
                    local cwd = nonempty_string(pane.pane_cwd)
                    local raw_command = nonempty_string(pane.pane_command)
                    local executable = raw_command and raw_command:match("%S+")
                    local directory = cwd and vim.fn.fnamemodify(cwd, ":t")
                    records[#records + 1] = {
                        pane_id = pane.id,
                        tab_id = pane.tab_id,
                        tab_position = pane.tab_position,
                        tab_name = name,
                        tab_tag = tag,
                        cwd = cwd,
                        directory = nonempty_string(directory) or cwd or title,
                        raw_command = raw_command,
                        command = executable and vim.fn.fnamemodify(executable, ":t") or "shell",
                        is_focused = pane.is_focused,
                        is_floating = pane.is_floating,
                        attention = type(pane.attention) == "table" and pane.attention or nil,
                    }
                end
            end
        end
        callback(records)
    end)
end

function M.dump_pane(pane_id, callback)
    action({ "dump-screen", "--pane-id", "terminal_" .. pane_id }, callback)
end

function M.send_message(pane_id, message, callback)
    local target = "terminal_" .. pane_id
    action({ "paste", "--pane-id", target, "--", message }, function(_, err)
        if err then
            callback(err)
            return
        end
        action({ "send-keys", "--pane-id", target, "Enter" }, function(_, submit_err)
            if submit_err then
                submit_err.message = "Message pasted. " .. submit_err.message
            end
            callback(submit_err)
        end)
    end)
end

function M.focus(tab, focused_pane, callback)
    local target = tab.pane_id
    if focused_pane == target then
        callback()
        return
    end
    M.focus_pane(tab.pane_id, function(err)
        if err then
            callback(err.message)
            return
        end
        M.clients(function(clients, client_err)
            if client_err then
                callback(client_err.message)
            elseif #clients ~= 1 then
                callback("Zellij focus requires one client attached to " .. M.session_name())
            elseif clients[1] == target then
                callback()
            else
                -- Until a client sends its first key, focus-pane-id can route to the CLI
                -- client. go-to-tab-by-id falls back to the attached client.
                M.focus_tab(tab.tab_id, function(tab_err)
                    if tab_err then
                        callback(tab_err.message)
                        return
                    end
                    M.clients(function(updated, verify_err)
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

return M
