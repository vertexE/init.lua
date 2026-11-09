local M = {}

local session = "nvim-mux"

local function failure(kind, message)
    return { kind = kind, message = message }
end

function M.session_name()
    return session
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
                clients[#clients + 1] = pane
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

local function split_tab_name(name)
    local tag, title = name:match("^%[#([^%]]+)%] (.+)$")
    if not tag then
        return nil, name
    end
    return (tag:gsub("%%5D", "]"):gsub("%%25", "%%")), title
end

function M.set_tab_tag(tab_id, name, tag, callback)
    local _, title = split_tab_name(name)
    if tag then
        local escaped = tag:gsub("%%", "%%25"):gsub("%]", "%%5D")
        title = "[#" .. escaped .. "] " .. title
    end
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

        local decoded, panes = pcall(vim.json.decode, stdout)
        if not decoded or not vim.islist(panes) then
            callback(nil, failure("invalid_json", "Zellij list-panes did not return a JSON array"))
            return
        end

        local records = {}
        for _, pane in ipairs(panes) do
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
                    local tag, title = split_tab_name(name)
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

local function focus_rank(pane)
    if not pane.is_focused then
        return 0
    end
    return pane.is_floating and 2 or 1
end

function M.tabs(callback)
    M.panes(function(panes, err)
        if err then
            callback(nil, err)
            return
        end

        local by_tab = {}
        for _, pane in ipairs(panes) do
            local previous = by_tab[pane.tab_id]
            if not previous or focus_rank(pane) > focus_rank(previous) then
                by_tab[pane.tab_id] = pane
            end
        end

        local tabs = vim.tbl_values(by_tab)
        table.sort(tabs, function(a, b)
            return a.tab_position < b.tab_position
        end)
        callback(tabs)
    end)
end

return M
