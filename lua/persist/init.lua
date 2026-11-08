local M = {}

---Run a schema operation. The callback receives (result, nil) or (nil, error)
---on Neovim's main loop.
---@param schema string
---@param operation string
---@param params table
---@param callback fun(result: any, err: string?)
function M.run(schema, operation, params, callback)
    local finish = vim.schedule_wrap(callback)
    if type(schema) ~= "string" or not schema:match("^[a-z][a-z0-9_]*$") then
        finish(nil, "Invalid persistence schema name")
        return
    end
    if type(params) ~= "table" then
        finish(nil, "Persistence operation params must be a table")
        return
    end

    local loaded, strategy = pcall(require, "persist.schemas." .. schema)
    if not loaded then
        finish(nil, ("Could not load persistence schema %s: %s"):format(schema, strategy))
        return
    end
    local action = strategy[operation]
    if type(action) ~= "function" then
        finish(nil, ("Unknown %s operation: %s"):format(schema, tostring(operation)))
        return
    end

    local started, err = pcall(action, params, finish)
    if not started then
        finish(nil, tostring(err))
    end
end

return M
