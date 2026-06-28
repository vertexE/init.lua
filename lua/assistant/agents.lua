local permissions = require("assistant.permissions")
local parsers = require("assistant.parsers")

local M = {}

local CODEX_MODEL = "gpt-5.4"
local CODEX_REASONING_EFFORT = "low"

--- @class Agent
--- @field prompt Prompt
--- @field session_id string|nil provider session handle; Codex stores its `thread_id` here
--- @field status "INACTIVE"|"ACTIVE"
local Agent = {}
Agent.__index = Agent

--- @param prompt Prompt
--- @return Agent
function Agent:new(prompt)
    return setmetatable({
        prompt = prompt,
        session_id = nil,
        status = "ACTIVE",
    }, self)
end

--- @type table<string,Agent>
local active_agents = {}

--- @param agent Agent
--- @param result vim.SystemCompleted
--- @param provider string
--- @param resolve fun(s:string)
--- @param reject ?fun(result:vim.SystemCompleted)
local complete_run = function(agent, result, provider, resolve, reject)
    if result.code ~= 0 and reject then
        reject(result)
    elseif result.stdout and #result.stdout > 0 then
        resolve(result.stdout)
    elseif result.stderr and #result.stderr > 0 then
        if reject then
            reject(result)
        else
            vim.notify(string.format("(%s): %s", provider, result.stderr), vim.log.levels.ERROR)
        end
    end

    agent.status = "INACTIVE"
end

--- @param prompt Prompt
--- @param cmd string[]
--- @param opts ?table<string,any>
--- @param resolve fun(s:string)
--- @param reject ?fun(result:vim.SystemCompleted)
--- @param provider string
--- @return Agent
local run_agent = function(prompt, cmd, opts, resolve, reject, provider)
    local agent = active_agents[prompt.id] or Agent:new(prompt)
    agent.prompt = prompt
    active_agents[prompt.id] = agent
    agent.status = "ACTIVE"
    vim.api.nvim_exec_autocmds("User", { pattern = "AgentStatusChange" })

    opts = vim.tbl_extend("force", { text = true, cwd = prompt.exec_dir }, opts or {})
    vim.system(
        cmd,
        opts,
        vim.schedule_wrap(function(result)
            complete_run(agent, result, provider, resolve, reject)
        end)
    )

    return agent
end

--- @param filter "INACTIVE"|"ACTIVE"|nil
--- @return Agent[]
M.list_agents = function(filter)
    return vim.iter(vim.tbl_values(active_agents))
        :filter(function(agent)
            return filter == nil or agent.status == filter
        end)
        :totable()
end

--- @param prompt Prompt
--- @param resolve fun(s:string)
--- @param reject ?fun(result:vim.SystemCompleted)
M.claude = function(prompt, resolve, reject)
    local agent = active_agents[prompt.id] or Agent:new(prompt)
    local session_id = agent.session_id
    local cmd = {
        "claude",
        "-p",
        -- nil check, if there exists an active session then ignore_rules = true
        prompt:as_string(session_id ~= nil),
        "--allowedTools",
        '"Bash(git diff:*)"',
    }

    if session_id then
        table.insert(cmd, "--resume")
        table.insert(cmd, session_id)
    elseif prompt.session_id then
        table.insert(cmd, "--session-id")
        table.insert(cmd, prompt.session_id)
        agent.session_id = prompt.session_id
    end

    if vim.tbl_contains(prompt.permissions, permissions.WRITE) then
        table.insert(cmd, "--permission-mode")
        table.insert(cmd, "acceptEdits")
    elseif vim.tbl_contains(prompt.permissions, permissions.PLAN) then
        table.insert(cmd, "--permission-mode")
        table.insert(cmd, "plan")
    end

    run_agent(prompt, cmd, nil, resolve, reject, "claude")
end

--- @param prompt Prompt
--- @param resolve fun(s:string)
--- @param reject ?fun(result:vim.SystemCompleted)
M.codex = function(prompt, resolve, reject)
    local agent = active_agents[prompt.id] or Agent:new(prompt)
    local session_id = agent.session_id or prompt.session_id
    local cmd = {
        "codex",
        "exec",
        "--json",
        "-m",
        CODEX_MODEL,
        "-c",
        string.format('reasoning_effort="%s"', CODEX_REASONING_EFFORT),
    }

    local prompt_input = prompt:as_string(session_id ~= nil and #session_id > 0)

    if session_id and #session_id > 0 then
        table.insert(cmd, "resume")
        table.insert(cmd, session_id)
    end

    table.insert(cmd, "-")

    agent = run_agent(prompt, cmd, { stdin = prompt_input }, function(stdout)
        local text, thread_id = parsers.codex_output(stdout)
        if thread_id and #thread_id > 0 then
            agent.session_id = thread_id
            prompt.session_id = thread_id
        end

        if text and #text > 0 then
            resolve(text)
            return
        end

        resolve(stdout)
    end, reject, "codex")
end

return M
