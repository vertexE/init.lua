local M = {}

local timer
local subscribers = {}
local debounces = {}

local function cancel_debounce(pane_id)
    local debounce = debounces[pane_id]
    if debounce then
        debounce:stop()
        debounce:close()
        debounces[pane_id] = nil
    end
end

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

function M.start(strategy, opts)
    if timer then
        return
    end

    opts = opts or {}
    local sound = vim.F.if_nil(opts.sound, vim.fn.has("mac") == 1)
    local sound_path = opts.sound_path or "/System/Library/Sounds/Glass.aiff"
    local active_panes = {}
    local function is_active(pane_id)
        return opts.is_terminal_focused and opts.is_terminal_focused() and active_panes[pane_id]
    end
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
        local function query()
            strategy.panes(function(panes, err)
                if timer ~= monitor then
                    return
                end
                pending = false
                if panes then
                    for _, pane in ipairs(panes) do
                        local active = is_active(pane.pane_id)
                        if active then
                            cancel_debounce(pane.pane_id)
                        end
                        local state = M.from_pane(pane)
                        local previous_status = last_statuses[pane.pane_id]
                        local finished = previous_status == "working"
                            and state.status == "done"
                            and pane.attention.source ~= "PaneIdle"
                        last_statuses[pane.pane_id] = state.status
                        local alert = alerts[state.status]
                        if alert then
                            local message = pane.attention.source == "PaneIdle" and "ready to be looked at" or alert.text
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
                                cancel_debounce(pane.pane_id)
                                if (state.unread or finished) and not baseline and not active then
                                    local function notify()
                                        debounces[pane.pane_id] = nil
                                        if timer ~= monitor or is_active(pane.pane_id) then
                                            return
                                        end
                                        vim.notify(
                                            ("%s · %s %s"):format(pane.directory, pane.command, message),
                                            alert.level,
                                            { title = "Plex" }
                                        )
                                        if sound then
                                            pcall(vim.system, { "afplay", sound_path }, { detach = true }, function() end)
                                        end
                                    end
                                    if pane.attention.source == "PaneIdle" then
                                        notify()
                                    else
                                        debounces[pane.pane_id] = vim.defer_fn(notify, 2000)
                                    end
                                end
                            end
                        else
                            cancel_debounce(pane.pane_id)
                        end
                    end
                    baseline = false
                end
                for callback in pairs(subscribers) do
                    callback(panes, err)
                end
            end, active_panes)
        end
        active_panes = {}
        if opts.is_terminal_focused and opts.is_terminal_focused() then
            strategy.clients(function(clients)
                if timer ~= monitor then
                    return
                end
                for _, client in ipairs(clients or {}) do
                    active_panes[client] = true
                end
                query()
            end)
        else
            query()
        end
    end))
end

function M.stop()
    for pane_id in pairs(debounces) do
        cancel_debounce(pane_id)
    end
    if timer then
        timer:stop()
        timer:close()
        timer = nil
    end
end

return M
