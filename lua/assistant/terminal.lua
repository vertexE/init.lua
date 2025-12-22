local M = {}

local prompts = require("assistant.prompts")
-- local resources = require("assistant.resources")

-- local state = { has_session = false }

--[[
-- PLAN --
-- - use a claude-status.md in the active repo
-- - add to global gitignore
-- - ask claude to push updates
-- - read from file to then display in status panel
-- - this allows us to know what it's working on... refreshing as we go
--]]

--- @class claude.msg_ctx
--- @field req_bufnr integer
--- @field sel_start integer
--- @field sel_end integer

--- @param ctx claude.msg_ctx
M.msg_claude = function(ctx)
    local status = vim.api.nvim_get_mode()
    require("sidekick.cli").send({
        name = "claude",
        msg = prompts.default({
            mode = status.mode,
            req_bufnr = ctx.req_bufnr,
            sel_start = ctx.sel_start,
            sel_end = ctx.sel_end,
        }),
        focus = true,
    })
end

return M
