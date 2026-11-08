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

local function body_sql(body)
    if type(body) ~= "string" or not body:find("%S") then
        error("Todo body must be a nonblank string", 0)
    end
    -- Encode text bytes so user input cannot change the SQL statement.
    local hex = body:gsub(".", function(byte)
        return ("%02x"):format(byte:byte())
    end)
    return ("CAST(X'%s' AS TEXT)"):format(hex)
end

function M.add(params, callback)
    query(("INSERT INTO todos (body) VALUES (%s) RETURNING *;"):format(body_sql(params.body)), function(rows, err)
        callback(rows and rows[1], err)
    end)
end

function M.list(_, callback)
    query("SELECT *, date(done_at, 'localtime') AS complete_at FROM todos ORDER BY id;", callback)
end

local function change_row(statement, id, callback)
    if type(id) ~= "number" or id < 1 or id > 9007199254740991 or id % 1 ~= 0 then
        callback(nil, "Todo id must be a positive safe integer")
        return
    end

    query(statement .. (" WHERE id = %.0f RETURNING *;"):format(id), function(rows, err)
        if rows and not rows[1] then
            callback(nil, ("Todo %.0f not found"):format(id))
            return
        end
        callback(rows and rows[1], err)
    end)
end

function M.complete(params, callback)
    change_row("UPDATE todos SET done_at = COALESCE(done_at, CURRENT_TIMESTAMP)", params.id, callback)
end

function M.toggle(params, callback)
    local statement = "UPDATE todos SET done_at = CASE WHEN done_at IS NULL THEN CURRENT_TIMESTAMP ELSE NULL END"
    change_row(statement, params.id, callback)
end

function M.edit(params, callback)
    change_row("UPDATE todos SET body = " .. body_sql(params.body), params.id, callback)
end

function M.delete(params, callback)
    change_row("DELETE FROM todos", params.id, callback)
end

return M
