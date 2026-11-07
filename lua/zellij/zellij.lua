local M = {}

local session = "nvim-mux"
local nightly = "43c8710b3a9845f60d5a567c7410fc1197fabb66"

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
    run({ "--version" }, "version check", function(stdout, err)
        if not err then
            local version = vim.version.parse(stdout:match("%d+%.%d+%.%d+") or "")
            if not version or vim.version.lt(version, "0.46.0") then
                err = failure("incompatible_version", "Zellij on PATH requires nightly " .. nightly .. " (0.46.0)")
            end
        end
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
                    or type(pane.attention) ~= "table"
                    or type(pane.attention.status) ~= "string"
                    or type(pane.attention.seen) ~= "boolean"
                    or type(pane.attention.changed_ms) ~= "number"
                then
                    callback(nil, failure("incompatible_version", "Zellij pane data requires nightly " .. nightly))
                    return
                end

                if pane.is_selectable and not pane.is_suppressed and not pane.exited then
                    local name = nonempty_string(pane.tab_name) or ("Tab #" .. (pane.tab_position + 1))
                    local cwd = nonempty_string(pane.pane_cwd)
                    local raw_command = nonempty_string(pane.pane_command)
                    local executable = raw_command and raw_command:match("%S+")
                    local directory = cwd and vim.fn.fnamemodify(cwd, ":t")
                    records[#records + 1] = {
                        pane_id = pane.id,
                        tab_id = pane.tab_id,
                        tab_position = pane.tab_position,
                        tab_name = name,
                        cwd = cwd,
                        directory = nonempty_string(directory) or cwd or name,
                        raw_command = raw_command,
                        command = executable and vim.fn.fnamemodify(executable, ":t") or "shell",
                        is_focused = pane.is_focused,
                        is_floating = pane.is_floating,
                        attention = pane.attention,
                    }
                end
            end
        end
        callback(records)
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
