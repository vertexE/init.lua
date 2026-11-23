local M = {}
local async = vim.async
local auth = require("spotify.auth")
local http = require("spotify.http")
local playback = { logged_in = false }
local watching, worker, timer, blocked_until = false, nil, nil, 0
local last_poll, setup = 0, false
local pending = {}

local function now()
    return vim.uv.hrtime() / 1e6
end

local function publish()
    vim.schedule(function()
        vim.api.nvim_exec_autocmds("User", { pattern = "SpotifyChanged", modeline = false })
    end)
end

local function request(method, path)
    if now() < blocked_until then
        error("Spotify: rate limited; waiting before next request", 0)
    end
    for attempt = 1, 2 do
        local token = auth.access()
        local data = http.request(method, "https://api.spotify.com/v1" .. path, {
            headers = { Authorization = "Bearer " .. token },
        })
        if not data or not data.error then
            return data
        end
        local status = type(data.error) == "table" and data.error.status
        if status == 401 and attempt == 1 then
            auth.invalidate()
        else
            if status == 429 then
                -- vim.net.request currently omits Retry-After headers.
                blocked_until = now() + 60000
            end
            local messages = {
                [401] = "authorization rejected; run :SpotifyLogin",
                [403] = "playback forbidden; check Premium, scopes and app allowlist",
                [404] = "no active Spotify device; open Spotify and start playback",
                [429] = "rate limited; waiting 60 seconds",
            }
            error("Spotify: " .. (messages[status] or "API request failed"), 0)
        end
    end
end

local function refresh()
    last_poll = now()
    local data = request("GET", "/me/player?additional_types=episode")
    local item = data and data.item
    local artists = {}
    if type(item) == "table" then
        for _, artist in ipairs(type(item.artists) == "table" and item.artists or {}) do
            artists[#artists + 1] = artist.name
        end
    else
        item = nil
    end
    playback = {
        logged_in = true,
        name = item and item.name,
        artist = item and (#artists > 0 and table.concat(artists, ", ")
            or type(item.show) == "table" and item.show.name or ""),
        duration_ms = item and tonumber(item.duration_ms) or 0,
        progress_ms = data and tonumber(data.progress_ms) or 0,
        is_playing = data and data.is_playing == true or false,
        currently_playing_type = data and data.currently_playing_type,
        sampled_at = now(),
    }
    last_poll = now()
end

local function run(fn, notify)
    if worker then
        if notify then
            pending[#pending + 1] = fn
        end
        return
    end
    if notify then
        pending[#pending + 1] = fn
    end
    worker = async.run(function()
        local operation = notify and table.remove(pending, 1) or fn
        local report = notify
        while operation do
            local ok, err = pcall(operation)
            if not ok then
                playback.progress_ms = M.progress()
                playback.sampled_at = now()
                playback.logged_in = auth.ready()
                playback.stale = true
                playback.error = tostring(err)
                if not playback.logged_in then
                    playback = { logged_in = false, error = tostring(err) }
                end
                if report then
                    vim.schedule(function()
                        vim.notify(tostring(err), vim.log.levels.ERROR)
                    end)
                end
            end
            publish()
            operation, report = table.remove(pending, 1), true
        end
    end)
    worker:on_complete(function()
        worker = nil
    end)
end

function M.get()
    return vim.deepcopy(playback)
end

function M.progress()
    local elapsed = playback.is_playing and not playback.stale and now() - (playback.sampled_at or now()) or 0
    return math.min(playback.duration_ms or 0, (playback.progress_ms or 0) + elapsed)
end

function M.refresh()
    run(function()
        auth.load()
        playback.logged_in = auth.ready()
        if playback.logged_in then
            refresh()
        end
    end)
end

function M.start()
    if watching then
        return
    end
    watching = true
    M.refresh()
    timer = vim.uv.new_timer()
    timer:start(1000, 1000, vim.schedule_wrap(function()
        if not watching then
            return
        end
        if playback.logged_in and now() >= blocked_until and (now() - last_poll >= 10000
            or playback.name and playback.is_playing and not playback.stale and now() - last_poll >= 2000
                and playback.duration_ms > 0 and M.progress() >= playback.duration_ms) then
            M.refresh()
        end
        if playback.name and playback.is_playing and not playback.stale then
            vim.api.nvim_exec_autocmds("User", { pattern = "SpotifyProgress", modeline = false })
        end
    end))
end

function M.stop()
    watching = false
    if timer then
        timer:stop()
        timer:close()
        timer = nil
    end
end

function M.toggle()
    run(function()
        refresh()
        request("PUT", playback.is_playing and "/me/player/pause" or "/me/player/play")
        refresh()
    end, true)
end

function M.next()
    run(function()
        request("POST", "/me/player/next")
        refresh()
    end, true)
end

function M.login()
    auth.login(function(exchange)
        run(function()
            exchange()
            refresh()
        end, true)
    end)
end

function M.setup()
    if setup then
        return
    end
    setup = true
    local group = vim.api.nvim_create_augroup("user.spotify", { clear = true })
    vim.api.nvim_create_autocmd("FocusGained", { group = group, callback = function()
        if watching then
            M.refresh()
        end
    end })
    vim.api.nvim_create_autocmd("VimLeavePre", { group = group, callback = function()
        M.stop()
        auth.stop()
        if worker then
            worker:close()
        end
    end })
end

return M
