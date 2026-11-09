-- Run from config root: nvim --headless -u NONE -i NONE -l tests/plex_tmux.lua
vim.opt.runtimepath:append(".")
local tmux = require("plex.tmux")
local panes = require("plex.panes")
local notify = require("plex.notify")
local temp = vim.fn.tempname()
assert(vim.fn.mkdir(temp, "p", 448) == 1)
vim.env.TMUX_TMPDIR = temp
vim.env.TMUX = nil
local function cli(...)
    local cmd = vim.list_extend({ "tmux", "-L", tmux.session_name() }, {...})
    local result = vim.system(cmd, { timeout = 2000 }):wait()
    assert(result.code == 0, vim.inspect({ cmd, result.stderr }))
    return result.stdout:gsub("\n$", "")
end
local function query(operation, ...)
    local complete, result, err
    local args = {...}
    args[#args + 1] = function(a, b)
        complete, result, err = true, a, b
    end
    operation(unpack(args))
    assert(vim.wait(6000, function() return complete end), "timeout")
    assert(not err, vim.inspect(err))
    return result
end
local function equal(expected, value)
    assert(vim.deep_equal(expected, value), vim.inspect({ expected = expected, actual = value }))
end
local function run()
    equal({}, query(tmux.clients))
    cli("-f", "/dev/null", "new-session", "-d", "-s", tmux.session_name(), "exec /bin/sh")
    local attach = vim.fn.jobstart({ "sh", "-c", tmux.attach_command() }, { pty = true })
    assert(attach > 0)
    local clients
    assert(vim.wait(4000, function()
        clients = query(tmux.clients)
        return #clients > 0
    end))
    equal({ "%0" }, clients)
    local first = query(panes.tabs, tmux)[1]
    equal("%0", first.pane_id)
    assert(vim.wait(4000, function()
        return cli("list-clients", "-F", "#{client_control_mode}"):find("1", 1, true)
    end))
    equal({ "%0" }, query(tmux.clients))

    local cwd = temp .. "/a\tβ #{} %41\nline\\;"
    assert(vim.fn.mkdir(cwd, "p", 448) == 1)
    equal(nil, query(tmux.new_tab, cwd))
    local tabs = query(panes.tabs, tmux)
    equal(2, #tabs)
    local second = tabs[2]
    equal(vim.uv.fs_realpath(cwd), second.cwd)
    equal({ "%0" }, query(tmux.clients))

    local tagged = query(tmux.set_tab_tag, second.tab_id, "test #{window_id};", "a%]β")
    equal("[#a%25%5Dβ] test #{window_id};", tagged)
    local renamed = query(panes.tabs, tmux)[2]
    equal(tagged, renamed.tab_name)
    equal("a%]β", renamed.tab_tag)

    local split = cli("split-window", "-d", "-P", "-F", "#{pane_id}", "-t", second.pane_id, "exec /bin/sh")
    equal(nil, query(tmux.focus, { tab_id = second.tab_id, pane_id = split }, first.pane_id))
    equal({ split }, query(tmux.clients))
    equal(split, query(panes.tabs, tmux)[2].pane_id)

    local function shell(pane, line)
        cli("send-keys", "-t", pane, "-l", line)
        cli("send-keys", "-t", pane, "Enter")
    end
    local function status(id, expected)
        assert(vim.wait(4000, function()
            for _, pane in ipairs(query(tmux.panes)) do
                if pane.pane_id == id and pane.attention and pane.attention.status == expected then
                    return true
                end
            end
        end), "Missing status " .. expected .. " for " .. id)
        for _, pane in ipairs(query(tmux.panes)) do
            if pane.pane_id == id then
                return pane.attention
            end
        end
    end
    local alerts = {}
    vim.notify = function(message) alerts[#alerts + 1] = message end
    notify.start(tmux, { sound = false, is_terminal_focused = function() return true end })
    -- Wait for the notification baseline before generating events.
    local baseline = false
    local unsubscribe = notify.subscribe(function() baseline = true end)
    assert(vim.wait(4000, function() return baseline end))
    unsubscribe()
    shell(first.pane_id, [[printf '\033]75'; sleep 0.1; printf '01;app=codex:state=working\033'; sleep 0.1; printf '\134']])
    status(first.pane_id, "Working")
    shell(first.pane_id, [[printf '\033]7501;state=blocked:kind=permission\007']])
    equal("Permission", status(first.pane_id, "NeedsYou").detail.kind)
    shell(first.pane_id, [[printf '\033]7501;state=working:id=child\007']])
    equal("Permission", status(first.pane_id, "NeedsYou").detail.kind)
    assert(vim.wait(4500, function() return #alerts > 0 end))
    assert(alerts[1]:match("needs permission$"), vim.inspect(alerts))
    shell(first.pane_id, [[printf '\033]7501;state=done:app=codex\033\134']])
    status(first.pane_id, "Done")
    assert(vim.wait(4500, function() return #alerts > 1 end))
    assert(alerts[2]:match("finished$"), vim.inspect(alerts))

    shell(split, [[printf '\033]7501;state=done:app=codex\007']])
    local function seen()
        for _, pane in ipairs(query(tmux.panes)) do
            if pane.pane_id == split then
                return pane.attention and pane.attention.seen
            end
        end
    end
    assert(vim.wait(4000, seen))
    vim.wait(2100)
    equal(2, #alerts)

    local capture = temp .. "/message"
    shell(split, "stty raw -echo; head -c 15 > " .. vim.fn.shellescape(capture) .. "; stty sane")
    vim.wait(300)
    equal(nil, query(tmux.send_message, split, "test\nline; 'λ"))
    assert(vim.wait(2000, function() return vim.uv.fs_stat(capture) ~= nil end))
    local file = assert(io.open(capture, "rb"))
    equal("test\nline; 'λ\r", file:read("*a"))
    file:close()
    print("Plex tmux integration passed")
end
local ok, err = xpcall(run, debug.traceback)
notify.stop()
tmux.stop()
pcall(cli, "kill-server")
vim.fn.delete(temp, "rf")
assert(ok, err)
