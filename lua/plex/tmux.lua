local panes = require("plex.panes")

local M = { name = "tmux" }
local session = "nvim-mux"
local target_session = "=" .. session
local observer
local status_prefix = "\027]7501;"
local statuses = {
    idle = "Idle",
    clear = "Idle",
    working = "Working",
    blocked = "NeedsYou",
    done = "Done",
    error = "Failed",
}
local kinds = { permission = "Permission", question = "Question", auth = "Auth" }

function M.session_name()
    return session
end

function M.attach_command()
    return "exec env -u TMUX tmux -L " .. session .. " new-session -A -s " .. session
end

local function command(args)
    return vim.list_extend({ "tmux", "-L", session }, args)
end

local function run(args, callback, stdin)
    local ok, err = pcall(vim.system, command(args), { timeout = 5000, stdin = stdin }, vim.schedule_wrap(function(result)
        if result.code ~= 0 then
            local detail = vim.trim(result.stderr or "")
            callback(nil, {
                kind = "command_failed",
                message = "tmux " .. args[1] .. " failed: " .. (detail ~= "" and detail or ("exit " .. result.code)),
                detail = detail,
            })
            return
        end
        callback(result.stdout or "")
    end))
    if not ok then
        callback(nil, { kind = "command_failed", message = "Could not start tmux: " .. tostring(err) })
    end
end

function M.check_version(callback)
    run({ "-V" }, function(_, err)
        callback(err)
    end)
end

function M.clients(callback)
    run({ "list-clients", "-t", target_session, "-F", "#{client_control_mode}:#{pane_id}" }, function(stdout, err)
        if err then
            if err.detail and (err.detail:match("^no server running") or err.detail:match("^error connecting")
                or err.detail:match("^can't find session:"))
            then
                callback({})
            else
                callback(nil, err)
            end
            return
        end
        local clients = {}
        for pane_id in stdout:gmatch("0:(%%%d+)") do
            clients[#clients + 1] = pane_id
        end
        callback(clients)
    end)
end

function M.focus(tab, focused_pane, callback)
    if focused_pane == tab.pane_id then
        callback()
        return
    end
    run({ "select-window", "-t", session .. ":" .. tab.tab_id, ";", "select-pane", "-t", tab.pane_id },
        function(_, err)
            callback(err and err.message)
        end)
end

local function literal_format(value)
    -- tmux expands formats and treats a trailing semicolon as a command separator.
    return (value:gsub("#", "##"):gsub(";$", "\\;"))
end

function M.new_tab(cwd, callback)
    run({ "new-window", "-d", "-t", session .. ":", "-c", literal_format(cwd) }, function(_, err)
        callback(err)
    end)
end

function M.set_tab_tag(tab_id, name, tag, callback)
    local title = panes.tagged_name(name, tag)
    run({ "rename-window", "-t", session .. ":" .. tab_id, "--", literal_format(title) }, function(_, err)
        callback(not err and title or nil, err)
    end)
end

function M.send_message(pane_id, message, callback)
    local buffer = ("plex-%d-%s"):format(vim.uv.os_getpid(), tostring(vim.uv.hrtime()))
    run({ "load-buffer", "-b", buffer, "-" }, function(_, err)
        if err then
            callback(err)
            return
        end
        run({
            "paste-buffer", "-p", "-r", "-d", "-b", buffer, "-t", pane_id,
            ";", "send-keys", "-t", pane_id, "Enter",
        }, function(_, send_err)
            if not send_err then
                callback()
                return
            end
            run({ "delete-buffer", "-b", buffer }, function()
                callback(send_err)
            end)
        end)
    end, message)
end

local function update_status(state, pane_id, report)
    local fields = {}
    for key, value in report:gmatch("([%w_]+)=([^:]*)") do
        fields[key] = value
    end
    local status = statuses[fields.state]
    if not status or fields.id then
        return
    end
    local kind = kinds[fields.kind]
    local previous = state.attention[pane_id]
    if previous and previous.status == status and previous.detail.kind == kind then
        return
    end
    state.attention[pane_id] = {
        status = status,
        seen = status == "Idle",
        changed_ms = vim.uv.hrtime() / 1e6,
        source = "ProgramStatus",
        detail = { kind = kind },
    }
end

local function read_pane_output(state, pane_id, output)
    -- Control mode octal-escapes control bytes and backslashes.
    local data = (state.tails[pane_id] or "") .. output:gsub("\\([0-7][0-7][0-7])", function(octal)
        return string.char(tonumber(octal, 8))
    end)
    local offset = 1
    while true do
        local start, prefix_end = data:find(status_prefix, offset, true)
        if not start then
            -- Keep enough bytes for a prefix split across control-mode messages.
            state.tails[pane_id] = data:sub(math.max(offset, #data - #status_prefix + 2))
            return
        end
        local stop = data:find("[\007\027]", prefix_end + 1)
        if not stop or (data:sub(stop) == "\027") then
            state.tails[pane_id] = #data - start <= 4096 and data:sub(start) or nil
            return
        end
        if data:sub(stop, stop) == "\007" then
            update_status(state, pane_id, data:sub(prefix_end + 1, stop - 1))
            offset = stop + 1
        elseif data:sub(stop, stop + 1) == "\027\\" then
            update_status(state, pane_id, data:sub(prefix_end + 1, stop - 1))
            offset = stop + 2
        else
            offset = stop
        end
    end
end

local function observe()
    if observer then
        return
    end
    local state = { attention = {}, tails = {}, listed = {} }
    local pending = ""
    -- A read-only client can prevent send-keys when tmux picks it for the target pane.
    local args = { "-C", "attach-session", "-f", "ignore-size", "-E", "-t", target_session }
    local ok, process = pcall(vim.system, command(args), {
        stdin = true,
        stdout = function(_, chunk)
            if observer ~= state or not chunk then
                return
            end
            local data = pending .. chunk
            local offset = 1
            for line, next_offset in data:gmatch("([^\n]*)\n()") do
                local id, output = line:match("^%%output (%%%d+) (.*)$")
                if id then
                    read_pane_output(state, id, output)
                end
                offset = next_offset
            end
            pending = data:sub(offset)
        end,
    }, function()
        if observer == state then
            observer = nil
        end
    end)
    if ok then
        state.process = process
        observer = state
    end
end

function M.stop()
    if observer then
        local process = observer.process
        observer = nil
        pcall(process.write, process, nil)
    end
end

local pane_format = table.concat({
    "#{pane_id}", "#{window_id}", "#{window_index}", "#{pane_active}",
    "#{q:window_name}", "#{q:pane_current_path}", "#{q:pane_current_command}",
}, "\t")

function M.panes(callback, active_panes)
    run({ "list-panes", "-s", "-t", target_session, "-f", "#{==:#{pane_dead},0}", "-F", pane_format },
        function(stdout, err)
            if err then
                callback(nil, err)
                return
            end
            observe()
            local state = observer
            local records, listed = {}, {}
            -- Protect escaped tabs and newlines before splitting format output.
            local escaped = stdout:gsub("\\(.)", function(char)
                return ("%%%02x"):format(char:byte())
            end)
            for line in escaped:gmatch("[^\n]+") do
                local fields = vim.split(line, "\t", { plain = true })
                for i = 5, 7 do
                    fields[i] = fields[i]:gsub("%%(%x%x)", function(hex)
                        return string.char(tonumber(hex, 16))
                    end)
                end
                local id, window, index, active, name, cwd, executable = unpack(fields)
                local tag, title = panes.split_tab_name(name)
                local directory = vim.fn.fnamemodify(cwd, ":t")
                local attention = state and state.attention[id]
                if attention and active_panes and active_panes[id] then
                    attention.seen = true
                end
                listed[id] = true
                records[#records + 1] = {
                    pane_id = id,
                    tab_id = window,
                    tab_position = tonumber(index),
                    tab_name = name,
                    tab_tag = tag,
                    cwd = cwd ~= "" and cwd or nil,
                    directory = directory ~= "" and directory or (cwd ~= "" and cwd or title),
                    command = executable ~= "" and executable or "shell",
                    is_focused = active == "1",
                    attention = attention,
                }
            end
            if state then
                for id in pairs(state.listed) do
                    if not listed[id] then
                        state.attention[id], state.tails[id] = nil, nil
                    end
                end
                state.listed = listed
            end
            callback(records)
        end)
end

return M
