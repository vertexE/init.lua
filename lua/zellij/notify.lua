local M = {}

local zellij = require("zellij.zellij")
local timer
local subscribers = {}

local statuses = {
    Working = "working",
    NeedsYou = "needs_input",
    Done = "done",
    Failed = "failed",
}

local kinds = {
    Permission = "permission",
    Question = "question",
    Auth = "auth",
}

local unseen_indicators = {
    needs_input = "orange",
    done = "orange",
    failed = "red",
}

local alerts = {
    needs_input = { text = "needs input", level = vim.log.levels.WARN },
    done = { text = "finished", level = vim.log.levels.INFO },
    failed = { text = "failed", level = vim.log.levels.ERROR },
}

local input_messages = {
    permission = "needs permission",
    question = "has a question",
    auth = "needs authentication",
}

function M.from_pane(pane)
    local attention = pane.attention or {}
    local status = statuses[attention.status] or "idle"
    local unread = attention.seen == false
    local detail = type(attention.detail) == "table" and attention.detail or {}

    return {
        status = status,
        unread = unread,
        kind = kinds[detail.kind],
        indicator = status == "working" and "spinner"
            or status == "needs_input" and "orange"
            or (unread and unseen_indicators[status])
            or "gray",
    }
end

function M.subscribe(callback)
    subscribers[callback] = true
    return function()
        subscribers[callback] = nil
    end
end

function M.start(opts)
    if timer then
        return
    end

    opts = opts or {}
    local sound = vim.F.if_nil(opts.sound, vim.fn.has("mac") == 1)
    local sound_path = opts.sound_path or "/System/Library/Sounds/Glass.aiff"
    local last_events = {}
    local last_statuses = {}
    local baseline = true
    local pending = false
    local monitor = assert(vim.uv.new_timer())
    timer = monitor

    monitor:start(0, 1000, vim.schedule_wrap(function()
        if timer ~= monitor or pending then
            return
        end
        pending = true
        zellij.panes(function(panes, err)
            pending = false
            if timer ~= monitor then
                return
            end
            if panes then
                for _, pane in ipairs(panes) do
                    local state = M.from_pane(pane)
                    local finished = last_statuses[pane.pane_id] == "working" and state.status == "done"
                    last_statuses[pane.pane_id] = state.status
                    local alert = alerts[state.status]
                    if alert then
                        local message = alert.text
                        if state.status == "needs_input" then
                            message = input_messages[state.kind]
                                or (pane.attention.source == "Bell" and "rang bell")
                                or message
                        end
                        local events = last_events[pane.pane_id] or {}
                        last_events[pane.pane_id] = events
                        local changed_ms = pane.attention.changed_ms
                        if events[state.status] ~= changed_ms then
                            events[state.status] = changed_ms
                            if (state.unread or finished) and not baseline then
                                vim.notify(
                                    ("%s · %s %s"):format(pane.directory, pane.command, message),
                                    alert.level,
                                    { title = "Zellij" }
                                )
                                if sound then
                                    pcall(vim.system, { "afplay", sound_path }, { detach = true }, function() end)
                                end
                            end
                        end
                    end
                end
                baseline = false
            end
            for callback in pairs(subscribers) do
                callback(panes, err)
            end
        end)
    end))
end

function M.stop()
    if timer then
        timer:stop()
        timer:close()
        timer = nil
    end
end

return M
