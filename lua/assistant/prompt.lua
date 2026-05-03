--- @class Prompt
--- @field permissions AgentPermission[]
--- @field session_id string default randomly generated
--- @field exec_dir string default exec_dir is current dir
--- @field rules string
--- @field task string
--- @field strategy AgentStrategy
local Prompt = {}
Prompt.__index = Prompt

--- @param permissions AgentPermission[]
--- @param session_id string default randomly generated
--- @param exec_dir string default exec_dir is current dir
--- @param rules string
--- @param task string
--- @param strategy AgentStrategy
--- @return Prompt
function Prompt:new(permissions, session_id, exec_dir, rules, task, strategy)
    return setmetatable({
        permissions = permissions,
        session_id = session_id,
        exec_dir = exec_dir,
        rules = rules,
        task = task,
        strategy = strategy,
    }, self)
end

--- @param ignore_rules boolean|nil
function Prompt:as_string(ignore_rules)
    local s = ""

    if not ignore_rules and self.rules and #self.rules > 0 then
        s = string.format("<rules>%s</rules>", self.rules)
    end

    if self.task and #self.task > 0 then
        s = string.format("%s\n<task>%s</task>", s, self.task)
    end

    return s
end

--- @param task string
function Prompt:set_task(task)
    self.task = task
end

--- run the provided prompt against the agent
--- @param resolve fun(s:string)
function Prompt:run(resolve)
    self.strategy(self, resolve)
end

return Prompt
