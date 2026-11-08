local M = {}

local create_table = [[
    CREATE TABLE IF NOT EXISTS todos (
        id INTEGER PRIMARY KEY,
        body TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        done_at TEXT
    );
]]

local function query(sql, callback)
    if vim.fn.executable("sqlite3") == 0 then
        callback(nil, "sqlite3 executable missing from PATH")
        return
    end

    local dir = vim.fn.stdpath("state")
    vim.fn.mkdir(dir, "p")
    local db = vim.fs.joinpath(dir, "todos.sqlite3")
    local empty_init = vim.fn.has("win32") == 1 and "NUL" or "/dev/null"
    local command = { "sqlite3", "-init", empty_init, "-batch", "-bail", "-json", "-cmd", ".timeout 2000", db }
    vim.system(command, { stdin = create_table .. sql, text = true }, function(result)
        if result.code ~= 0 then
            local detail = vim.trim(result.stderr or "")
            callback(nil, detail ~= "" and detail or ("sqlite3 exited with code %d"):format(result.code))
            return
        end

        local stdout = result.stdout or ""
        if stdout == "" then
            callback({})
            return
        end

        local decoded, rows = pcall(vim.json.decode, stdout, { luanil = { object = true } })
        if not decoded or not vim.islist(rows) then
            callback(nil, "sqlite3 did not return a JSON array")
            return
        end
        callback(rows)
    end)
end

function M.add(params, callback)
    if type(params.body) ~= "string" or not params.body:find("%S") then
        callback(nil, "Todo body must be a nonblank string")
        return
    end

    -- Encode text bytes so user input cannot change the SQL statement.
    local hex = params.body:gsub(".", function(byte)
        return ("%02x"):format(byte:byte())
    end)
    query(("INSERT INTO todos (body) VALUES (CAST(X'%s' AS TEXT)) RETURNING *;"):format(hex), function(rows, err)
        callback(rows and rows[1], err)
    end)
end

function M.list(_, callback)
    query("SELECT * FROM todos ORDER BY id;", callback)
end

function M.complete(params, callback)
    local id = params.id
    if type(id) ~= "number" or id < 1 or id > 9007199254740991 or id % 1 ~= 0 then
        callback(nil, "Todo id must be a positive safe integer")
        return
    end

    local sql = ("UPDATE todos SET done_at = COALESCE(done_at, CURRENT_TIMESTAMP) WHERE id = %.0f RETURNING *;")
        :format(id)
    query(sql, function(rows, err)
        if rows and not rows[1] then
            callback(nil, ("Todo %.0f not found"):format(id))
            return
        end
        callback(rows and rows[1], err)
    end)
end

return M
