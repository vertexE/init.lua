local resources = require("assistant.resources")
local agents = require("assistant.agents")

local M = {}

M.provider_strategy = function()
    return resources.agent_name() == "Codex" and agents.codex or agents.claude
end

return M
