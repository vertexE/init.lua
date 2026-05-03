local permissions = require("assistant.permissions")

local M = {}

--- @class Agent
--- @field prompt Prompt
--- @field status "INACTIVE"|"ACTIVE"
local Agent = {}
Agent.__index = Agent

--- @param prompt Prompt
--- @return Agent
function Agent:new(prompt)
    return setmetatable({
        prompt = prompt,
        status = "ACTIVE",
    }, self)
end

--- @type table<string,Agent>
local active_sessions = {}

-- TODO: we can add an M.list_agents func for "resources" to use
-- this can be consumed by "ui.status" to show running agents...
-- can add spinners on the bottom using "ui.loader"

--- @param prompt Prompt
--- @param resolve fun(s:string)
M.claude = function(prompt, resolve)
    local agent = active_sessions[prompt.session_id] or Agent:new(prompt)
    local cmd = { "claude", "-p", prompt:as_string(agent ~= nil), "--allowedTools", '"Bash(git diff:*)"' }

    if active_sessions[prompt.session_id] then
        table.insert(cmd, "--resume")
        table.insert(cmd, prompt.session_id)
    else
        active_sessions[prompt.session_id] = agent
        table.insert(cmd, "--session-id")
        table.insert(cmd, prompt.session_id)
    end

    if vim.tbl_contains(prompt.permissions, permissions.WRITE) then
        table.insert(cmd, "--permission-mode")
        table.insert(cmd, "acceptEdits")
    elseif vim.tbl_contains(prompt.permissions, permissions.PLAN) then
        table.insert(cmd, "--permission-mode")
        table.insert(cmd, "plan")
    end

    agent.status = "ACTIVE"
    vim.system(
        cmd,
        { text = true },
        vim.schedule_wrap(function(result)
            if result.stdout and #result.stdout > 0 then
                resolve(result.stdout)
            elseif result.stderr and #result.stderr > 0 then
                vim.notify(string.format("(claude): %s", result.stderr), vim.log.levels.ERROR)
            end
            agent.status = "INACTIVE"
        end)
    )
end

return M
