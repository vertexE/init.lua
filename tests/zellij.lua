-- Run from config root: nvim --headless -u NONE -i NONE -l tests/zellij.lua
vim.opt.runtimepath:prepend(".")

local zellij = require("plex.zellij")
local panes = require("plex.panes")
local notify = require("plex.notify")

local function equal(expected, actual)
    assert(vim.deep_equal(expected, actual), vim.inspect({ expected = expected, actual = actual }))
end

local function pane(id, fields)
    return vim.tbl_extend("force", {
        id = id,
        tab_id = 19,
        tab_position = 2,
        tab_name = "Projects",
        is_plugin = false,
        is_selectable = true,
        is_focused = false,
        is_floating = false,
        is_suppressed = false,
        exited = false,
        attention = { status = "Idle", seen = true, changed_ms = 0 },
    }, fields or {})
end

local response
local executable = 1
vim.fn.executable = function(name)
    equal("zellij", name)
    return executable
end
local expected_command = { "zellij", "--session", "nvim-mux", "action", "list-panes", "--all", "--json" }
vim.system = function(command, _, callback)
    equal(expected_command, command)
    callback(response)
end

local function query()
    local done, tabs, err
    panes.tabs(zellij, function(result, failure)
        done, tabs, err = true, result, failure
    end)
    assert(vim.wait(1000, function()
        return done
    end))
    return tabs, err
end

equal("nvim-mux", zellij.session_name())
executable = 0
local _, err = query()
equal("missing_binary", err.kind)
executable = 1

response = {
    code = 0,
    stdout = vim.json.encode({
        pane(1, { is_focused = true, is_floating = true, is_plugin = true }),
        pane(2, { is_focused = true, is_floating = true, is_suppressed = true }),
        pane(3, { is_focused = true, is_floating = true, exited = true }),
        pane(4, { is_focused = true, is_floating = true, is_selectable = false }),
        pane(5, { is_focused = true }),
        pane(6, {
            is_focused = true,
            is_floating = true,
            pane_cwd = "/work/project",
            pane_command = "/usr/local/bin/codex --resume",
            attention = { status = "NeedsYou", seen = false, changed_ms = 42, detail = { kind = "Question" } },
        }),
        pane(7, { tab_id = 21, tab_position = 0, tab_name = "Fallback" }),
        pane(8, { tab_id = 21, tab_position = 0 }),
        pane(9, { tab_id = 22, tab_position = 1, is_floating = true }),
        pane(10, { tab_id = 22, tab_position = 1, is_focused = true }),
    }),
}
local tabs = query()
equal({ 7, 10, 6 }, vim.tbl_map(function(tab)
    return tab.pane_id
end, tabs))
equal("Fallback", tabs[1].directory)
equal("shell", tabs[1].command)
equal("project", tabs[3].directory)
equal("/work/project", tabs[3].cwd)
equal("codex", tabs[3].command)
equal("/usr/local/bin/codex --resume", tabs[3].raw_command)
equal(42, tabs[3].attention.changed_ms)
equal({ status = "needs_input", unread = true, kind = "question", indicator = "orange" }, notify.from_pane(tabs[3]))

local indicators = {
    Idle = { "gray", "gray" },
    Working = { "spinner", "spinner" },
    NeedsYou = { "orange", "orange" },
    Done = { "orange", "gray" },
    Failed = { "red", "gray" },
    NewOutput = { "gray", "gray" },
    Quiet = { "gray", "gray" },
}
for status, expected in pairs(indicators) do
    equal(expected[1], notify.from_pane({ attention = { status = status, seen = false } }).indicator)
    equal(expected[2], notify.from_pane({ attention = { status = status, seen = true } }).indicator)
end
equal("gray", notify.from_pane({}).indicator)
equal({ status = "needs_input", unread = false, kind = "question", indicator = "orange" }, notify.from_pane({
    attention = { status = "NeedsYou", seen = true, detail = { kind = "Question" } },
}))

response = { code = 0, stdout = "[]" }
equal({}, query())
response = { code = 0, stdout = "{" }
_, err = query()
equal("invalid_json", err.kind)
response = { code = 0, stdout = vim.json.encode({ pane(1, { attention = vim.NIL }) }) }
local fallback_tabs
fallback_tabs, err = query()
equal(nil, err)
equal(nil, fallback_tabs[1].attention)
response = { code = 0, stdout = vim.json.encode({ pane(1, { tab_id = vim.NIL }) }) }
_, err = query()
equal("incompatible_version", err.kind)
response = { code = 1, stderr = "Session not found\n" }
_, err = query()
equal("command_failed", err.kind)
assert(err.message:find("Session not found", 1, true))

local function check_version(stdout)
    response = { code = 0, stdout = stdout }
    local done, version_err
    zellij.check_version(function(failure)
        done, version_err = true, failure
    end)
    assert(vim.wait(1000, function()
        return done
    end))
    return version_err
end
expected_command = { "zellij", "--version" }
equal(nil, check_version("zellij 0.45.1\n"))
equal(nil, check_version("zellij 0.46.0\n"))

expected_command = { "zellij", "--session", "nvim-mux", "action", "dump-screen", "--pane-id", "terminal_6" }
response = { code = 0, stdout = "agent output\n" }
local dumped
zellij.dump_pane(6, function(stdout, dump_err)
    equal(nil, dump_err)
    dumped = stdout
end)
assert(vim.wait(1000, function() return dumped ~= nil end))
equal("agent output\n", dumped)

local levels = vim.log.levels
local messages, sounds = {}, {}
vim.notify = function(message, level)
    messages[#messages + 1] = { message, level }
end
local sample = vim.deepcopy(tabs[3])
local other_sample
zellij.panes = function(callback)
    callback(other_sample and { sample, other_sample } or { sample })
end
vim.system = function(command, opts)
    equal({ "afplay", "/test/sound.aiff" }, command)
    assert(opts.detach)
    sounds[#sounds + 1] = command
end
local deferred = {}
local defer_fn = vim.defer_fn
vim.defer_fn = function(callback, delay)
    equal(2000, delay)
    local job = { callback = callback }
    function job:stop() self.cancelled = true end
    function job:close() self.closed = true end
    deferred[#deferred + 1] = job
    return job
end
local function flush()
    local jobs = deferred
    deferred = {}
    for _, job in ipairs(jobs) do
        if not job.cancelled then job.callback() end
    end
end
local hold_debounces = false
local tick
local stopped, closed
local new_timer = vim.uv.new_timer
vim.uv.new_timer = function()
    return {
        start = function(_, delay, interval, callback)
            equal(0, delay)
            equal(1000, interval)
            tick = callback
        end,
        stop = function()
            stopped = true
        end,
        close = function()
            closed = true
        end,
    }
end
local polls = 0
local unsubscribe = notify.subscribe(function()
    polls = polls + 1
end)
local function poll(status, changed_ms, seen, source, kind)
    sample.attention = { status = status, changed_ms = changed_ms, seen = seen, source = source, detail = { kind = kind } }
    local previous = polls
    tick()
    assert(vim.wait(1000, function()
        return polls > previous
    end))
    if not hold_debounces then flush() end
end
local native_terminal_focused = false
zellij.clients = function(callback)
    callback({ sample.pane_id })
end
notify.start(zellij, {
    sound = true,
    sound_path = "/test/sound.aiff",
    is_terminal_focused = function() return native_terminal_focused end,
})
vim.uv.new_timer = new_timer
poll("NeedsYou", 42, false)
equal(0, #messages)
poll("Working", 43, false)
poll("Done", 44, false)
poll("Done", 44, false)
poll("NeedsYou", 45, false)
poll("Failed", 46, true)
poll("Failed", 47, false)
poll("Working", 48, true)
poll("Done", 49, true)
poll("Done", 49, true)
poll("Done", 50, true)
poll("NeedsYou", 51, false, "Bell")
poll("NeedsYou", 52, false, "ProgramStatus", "Permission")
poll("NeedsYou", 53, false, "ProgramStatus", "Question")
poll("NeedsYou", 54, false, "ProgramStatus", "Auth")
-- Stable completion alerts after debounce, regardless of previous status.
poll("Done", 55, false)
poll("Done", 55, false)
-- Actual work after input still earns a completion alert.
poll("Working", 56, false)
poll("Done", 57, false)
equal({
    { "project · codex finished", levels.INFO },
    { "project · codex needs input", levels.WARN },
    { "project · codex failed", levels.ERROR },
    { "project · codex finished", levels.INFO },
    { "project · codex rang bell", levels.WARN },
    { "project · codex needs permission", levels.WARN },
    { "project · codex has a question", levels.WARN },
    { "project · codex needs authentication", levels.WARN },
    { "project · codex finished", levels.INFO },
    { "project · codex finished", levels.INFO },
}, messages)
equal(10, #sounds)
-- Burst updates coalesce per pane without delaying other panes.
messages, sounds = {}, {}
hold_debounces = true
other_sample = vim.deepcopy(sample)
other_sample.pane_id = 999
other_sample.attention = { status = "Working", changed_ms = 60, seen = false }
poll("Working", 60, false)
other_sample.attention = { status = "NeedsYou", changed_ms = 61, seen = false }
poll("NeedsYou", 61, false)
local first_job, other_job = deferred[1], deferred[2]
poll("Done", 62, false)
assert(first_job.cancelled and first_job.closed)
assert(not other_job.cancelled)
equal(0, #messages)
flush()
equal(2, #messages)
equal("project · codex needs input", messages[1][1])
equal("project · codex finished", messages[2][1])
-- Working cancels pending alert; stopping cancels remaining pane timers.
poll("NeedsYou", 63, false)
poll("Working", 64, false)
flush()
equal(2, #messages)
poll("Done", 65, false)
-- Focusing pane cancels queued alert; leaving does not replay it.
native_terminal_focused = true
poll("Done", 65, false)
flush()
equal(2, #messages)
poll("NeedsYou", 66, false)
flush()
equal(2, #messages)
native_terminal_focused = false
poll("NeedsYou", 66, false)
flush()
equal(2, #messages)
poll("Done", 67, false)
unsubscribe()
notify.stop()
assert(stopped and closed)
flush()
equal(2, #messages)
vim.defer_fn = defer_fn

-- Idle fallback: actual elapsed time, deduplication, resets, process filtering.
messages, sounds = {}, {}
local now = 0
local hrtime = vim.uv.hrtime
vim.uv.hrtime = function() return now * 1e6 end
local dump, dump_err = "prompt", nil
local dumps = 0
zellij.dump_pane = function(id, callback)
    equal(sample.pane_id, id)
    dumps = dumps + 1
    callback(dump, dump_err)
end
sample.attention = nil
other_sample = nil
zellij.panes = function(callback)
    callback({ vim.deepcopy(sample) })
end
vim.uv.new_timer = function()
    return {
        start = function(_, _, _, callback) tick = callback end,
        stop = function() end,
        close = function() end,
    }
end
local fallback_polls = 0
local unsubscribe_fallback = notify.subscribe(function() fallback_polls = fallback_polls + 1 end)
local function idle_poll(ms)
    now = ms
    local previous = fallback_polls
    tick()
    assert(vim.wait(1000, function() return fallback_polls > previous end))
end
local terminal_focused = false
local client_pane = sample.pane_id
zellij.clients = function(callback)
    callback({ client_pane })
end
notify.start(zellij, { sound = false, is_terminal_focused = function() return terminal_focused end })
vim.uv.new_timer = new_timer
idle_poll(0)
idle_poll(1999)
equal(0, #messages)
idle_poll(2000)
equal({ { "project · codex ready to be looked at", levels.INFO } }, messages)
idle_poll(5000)
equal(1, #messages)
dump = "new output"
idle_poll(6000)
idle_poll(7999)
equal(1, #messages)
idle_poll(8000)
equal(2, #messages)
sample.command = "bash"
local previous_dumps = dumps
idle_poll(9000)
equal(previous_dumps, dumps)
sample.command = "claude"
idle_poll(10000)
idle_poll(12000)
equal("project · claude ready to be looked at", messages[3][1])
dump_err = { kind = "command_failed" }
idle_poll(13000)
dump_err = nil
idle_poll(14000)
idle_poll(15999)
equal(3, #messages)
idle_poll(16000)
equal(4, #messages)
-- Typing pauses in viewed pane stay quiet; hiding does not replay observed output.
terminal_focused = true
dump = "typing"
idle_poll(17000)
idle_poll(19000)
equal(4, #messages)
dump = "typing more"
idle_poll(20000)
terminal_focused = false
idle_poll(22000)
equal(4, #messages)
idle_poll(24000)
equal(4, #messages)
-- New background output still earns an alert with terminal hidden.
dump = "background response"
idle_poll(25000)
idle_poll(27000)
equal(5, #messages)
-- Another pane receiving input must not suppress this pane.
terminal_focused = true
client_pane = sample.pane_id + 1
dump = "other background response"
idle_poll(28000)
idle_poll(30000)
equal(6, #messages)
notify.stop()
unsubscribe_fallback()
vim.uv.hrtime = hrtime
vim.uv.new_timer = new_timer

print("Zellij pane query and attention tests passed")
