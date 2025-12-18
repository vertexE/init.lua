--- this generates a plan, assistant will execute it step by step
local M = {}

local textarea = require("ui.textarea")

--- @alias llm.PlanStatus "planning"|"reviewable"|"executable"|"executing"|"completed"

--- @class llm.Plan
--- @field title string
--- @field status llm.PlanStatus
--- @field session_id string
--- @field location string file path pointing to where the plan is stored (in /tmp dir)

local state = {
    --- @type llm.Plan|nil
    active_plan = nil,
}

---
--- @param callback fun(goal: string, plan: llm.Plan)
M.create_plan = function(callback)
    vim.ui.input({ prompt = "Enter Title for Plan" }, function(title)
        if not title then
            return
        end

        local parsed_input = vim.trim(title)
        if #parsed_input == 0 then
            return
        end

        local file_name = vim.fn.tempname()
        textarea.open({ prompt = "󰛄 Plan", height = 0.3, width = 0.5 }, function(goal)
            if not goal or #goal == 0 then
                return
            end

            --- @type llm.Plan
            local _plan = {
                title = title,
                status = "planning",
                location = file_name,
                session_id = "",
            }

            state.active_plan = _plan
            callback(table.concat(goal, "\n"), _plan)
        end)
    end)
end

--- @return llm.Plan
M.active_plan = function()
    return state.active_plan
end

return M
