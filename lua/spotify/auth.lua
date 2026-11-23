local M = {}
local async = vim.async
local service = "nvim.spotify"
local redirect = "http://127.0.0.1:8888/callback"
local token, refresh_token, expires = nil, nil, 0
local loaded, refresh_task, login_cleanup = false, nil, nil

local function now()
    return vim.uv.hrtime() / 1e6
end

local function encode(value)
    return (value:gsub("[^%w%-._~]", function(c)
        return string.format("%%%02X", c:byte())
    end))
end

local function form(values)
    local parts = {}
    for key, value in pairs(values) do
        parts[#parts + 1] = encode(key) .. "=" .. encode(value)
    end
    return table.concat(parts, "&")
end

local function system(args)
    return async.await(3, vim.system, args, { text = true })
end

local function keychain(action, value)
    local args = { "security", action .. "-generic-password", "-s", service, "-a", vim.env.SPOTIFY_CLIENT_ID }
    if action == "find" then
        args[#args + 1] = "-w"
    elseif action == "add" then
        vim.list_extend(args, { "-U", "-w", value })
    end
    return system(args)
end

function M.configured()
    return (vim.env.SPOTIFY_CLIENT_ID or "") ~= "" and (vim.env.SPOTIFY_CLIENT_SECRET or "") ~= ""
end

function M.ready()
    return refresh_token ~= nil
end

function M.load()
    if loaded or not M.configured() then
        return
    end
    loaded = true
    local result = keychain("find")
    if result.code == 0 then
        refresh_token = result.stdout:gsub("%s+$", "")
        if refresh_token == "" then
            refresh_token = nil
        end
    elseif result.code ~= 44 then
        error("Spotify: Keychain read failed", 0)
    end
end

local function exchange(values)
    local credentials = vim.base64.encode(vim.env.SPOTIFY_CLIENT_ID .. ":" .. vim.env.SPOTIFY_CLIENT_SECRET)
    local data = require("spotify.http").request("POST", "https://accounts.spotify.com/api/token", {
        headers = { Authorization = "Basic " .. credentials, ["Content-Type"] = "application/x-www-form-urlencoded" },
        body = form(values),
    })
    assert(data, "Spotify: empty token response")
    if data.error then
        if data.error == "invalid_grant" then
            token, refresh_token, expires = nil, nil, 0
            keychain("delete")
            error("Spotify: authorization expired; run :SpotifyLogin", 0)
        end
        error("Spotify: token exchange rejected; check app credentials", 0)
    end
    assert(type(data.access_token) == "string" and type(data.expires_in) == "number", "Spotify: invalid token response")
    token, expires = data.access_token, now() + data.expires_in * 1000 - 60000
    if type(data.refresh_token) == "string" and data.refresh_token ~= refresh_token then
        refresh_token = data.refresh_token
        local result = keychain("add", refresh_token)
        if result.code ~= 0 then
            vim.schedule(function()
                vim.notify("Spotify: Keychain save failed; login will not survive restart", vim.log.levels.ERROR)
            end)
        end
    end
    return token
end

function M.access()
    M.load()
    if not refresh_token then
        error("Spotify: run :SpotifyLogin", 0)
    end
    if token and now() < expires then
        return token
    end
    if not refresh_task then
        refresh_task = async.run(function()
            return exchange({ grant_type = "refresh_token", refresh_token = refresh_token })
        end):detach()
        refresh_task:on_complete(function()
            refresh_task = nil
        end)
    end
    return async.await(refresh_task)
end

function M.invalidate()
    token, expires = nil, 0
end

function M.cancel_login()
    if login_cleanup then
        login_cleanup()
    end
end

function M.stop()
    M.cancel_login()
    if refresh_task then
        refresh_task:close()
    end
end

function M.login(on_login)
    if not M.configured() then
        vim.notify("Spotify: set SPOTIFY_CLIENT_ID and SPOTIFY_CLIENT_SECRET", vim.log.levels.ERROR)
        return
    end
    M.cancel_login()
    local nonce = assert(vim.uv.random(32)):gsub(".", function(c)
        return string.format("%02x", c:byte())
    end)
    local server, timer, clients = vim.uv.new_tcp(), vim.uv.new_timer(), {}
    local closed, accepted = false, false
    local function cleanup()
        if closed then
            return
        end
        closed = true
        timer:stop()
        timer:close()
        server:close()
        for client in pairs(clients) do
            if not client:is_closing() then
                client:close()
            end
        end
        login_cleanup = nil
    end
    login_cleanup = cleanup
    local bound = server:bind("127.0.0.1", 8888)
    if not bound then
        cleanup()
        vim.notify("Spotify: callback port 8888 unavailable", vim.log.levels.ERROR)
        return
    end
    local listening = server:listen(8, function(err)
        if err or closed then
            return
        end
        local client, request = vim.uv.new_tcp(), ""
        server:accept(client)
        clients[client] = true
        client:read_start(function(read_err, chunk)
            if read_err or not chunk then
                clients[client] = nil
                if not client:is_closing() then
                    client:close()
                end
                return
            end
            request = request .. chunk
            if #request > 16384 then
                clients[client] = nil
                client:close()
                return
            end
            if not request:find("\r\n\r\n", 1, true) then
                return
            end
            client:read_stop()
            local query = request:match("^GET /callback%?([^ ]+) HTTP/1%.[01]\r\n")
            local params = {}
            for key, value in (query or ""):gmatch("([^&=]+)=([^&]*)") do
                params[key] = value:gsub("+", " "):gsub("%%(%x%x)", function(hex)
                    return string.char(tonumber(hex, 16))
                end)
            end
            local valid = query and params.state == nonce and (params.code or params.error)
            if accepted then
                valid = false
            elseif valid then
                accepted = true
            end
            local message = valid and "Spotify callback received. Return to Neovim." or "Invalid Spotify callback."
            client:write("HTTP/1.1 " .. (valid and "200 OK" or "400 Bad Request")
                .. "\r\nContent-Type: text/plain\r\nConnection: close\r\nContent-Length: " .. #message .. "\r\n\r\n" .. message, function()
                clients[client] = nil
                if not client:is_closing() then
                    client:close()
                end
                if valid then
                    cleanup()
                    vim.schedule(function()
                        if params.error then
                            vim.notify("Spotify: authorization denied", vim.log.levels.WARN)
                            return
                        end
                        on_login(function()
                            if refresh_task then
                                async.pawait(refresh_task)
                            end
                            loaded = true
                            exchange({ grant_type = "authorization_code", code = params.code, redirect_uri = redirect })
                        end)
                    end)
                end
            end)
        end)
    end)
    if not listening then
        cleanup()
        vim.notify("Spotify: callback listener failed", vim.log.levels.ERROR)
        return
    end
    timer:start(120000, 0, vim.schedule_wrap(function()
        cleanup()
        vim.notify("Spotify: login timed out", vim.log.levels.WARN)
    end))
    local _, open_err = vim.ui.open("https://accounts.spotify.com/authorize?" .. form({
        client_id = vim.env.SPOTIFY_CLIENT_ID,
        response_type = "code",
        redirect_uri = redirect,
        scope = "user-read-playback-state user-modify-playback-state",
        state = nonce,
    }))
    if open_err then
        cleanup()
        vim.notify("Spotify: could not open browser", vim.log.levels.ERROR)
    end
end

return M
