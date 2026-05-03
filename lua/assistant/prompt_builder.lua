local Prompt = require("assistant.prompt")
local uuid = require("ids")

--- @alias AgentStrategy fun(agent:Prompt, resolve:fun(s:string))

--- @class PromptBuilder
--- @field permissions AgentPermission[]|nil
--- @field session_id string|nil default randomly generated
--- @field exec_dir string|nil default exec_dir is current dir
--- @field rules string|nil
--- @field task string|nil
--- @field strategy AgentStrategy|nil
local PromptBuilder = {}
PromptBuilder.__index = PromptBuilder

--- @return PromptBuilder
function PromptBuilder:new()
    return setmetatable({}, self)
end

--- @param permissions AgentPermission[]
--- @return PromptBuilder
function PromptBuilder:with_permissions(permissions)
    self.permissions = permissions
    return self
end

--- @param session_id string
--- @return PromptBuilder
function PromptBuilder:with_session_id(session_id)
    self.session_id = session_id
    return self
end

--- @param exec_dir string
--- @return PromptBuilder
function PromptBuilder:with_exec_dir(exec_dir)
    self.exec_dir = exec_dir
    return self
end

--- @param strategy AgentStrategy
--- @return PromptBuilder
function PromptBuilder:with_strategy(strategy)
    self.strategy = strategy
    return self
end

--- @param task string
--- @return PromptBuilder
function PromptBuilder:with_task(task)
    self.task = task
    return self
end

--- @param rules string
--- @return PromptBuilder
function PromptBuilder:with_rules(rules)
    self.rules = rules
    return self
end

function PromptBuilder:build()
    local permissions = self.permissions or {}
    local session_id = self.session_id or uuid.uuidv4()
    local exec_dir = self.exec_dir or vim.fn.getcwd()
    local rules = self.rules or ""
    local task = self.task or ""
    local strategy = self.strategy
        or function()
            vim.notify("(assistant): missing agent strategy in PromptBuilder", vim.log.levels.ERROR)
        end

    return Prompt:new(permissions, session_id, exec_dir, rules, task, strategy)
end

return PromptBuilder
