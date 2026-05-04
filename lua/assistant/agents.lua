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

--- @param filter "INACTIVE"|"ACTIVE"|nil
--- @return Agent[]
M.list_agents = function(filter)
    return vim.iter(vim.tbl_values(active_sessions))
        :filter(function(agent)
            return filter == nil or agent.status == filter
        end)
        :totable()
end

--- @param prompt Prompt
--- @param resolve fun(s:string)
M.claude = function(prompt, resolve)
    local cmd = {
        "claude",
        "-p",
        -- nil check, if there exists an active session then ignore_rules = true
        prompt:as_string(active_sessions[prompt.session_id] ~= nil),
        "--allowedTools",
        '"Bash(git diff:*)"',
    }
    local agent = active_sessions[prompt.session_id] or Agent:new(prompt)

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
    vim.api.nvim_exec_autocmds("User", { pattern = "AgentStatusChange" })

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
