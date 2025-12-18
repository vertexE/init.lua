local M = {}

local prompts = require("assistant.prompts")
local textarea = require("ui.textarea")
local resources = require("assistant.resources")

local state = { has_session = false }

--[[
-- PLAN --
-- - use a claude-status.md in the active repo
-- - add to global gitignore
-- - ask claude to push updates
-- - read from file to then display in status panel
-- - this allows us to know what it's working on... refreshing as we go
--]]

M.claude = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local sidekick = require("sidekick.cli")
    if state.has_session then
        sidekick.send({
            name = "claude",
            msg = resources.active(bufnr),
            focus = true,
        })
        return
    end

    textarea.open({ prompt = "󰛄 Claude", height = 0.5, width = 0.55 }, function(input)
        local status = vim.api.nvim_get_mode()
        sidekick.send({
            name = "claude",
            msg = prompts.default({ mode = status.mode, req_bufnr = bufnr, input = table.concat(input, "\n") }),
            focus = true,
        })
    end)

    state.has_session = true
end

return M
