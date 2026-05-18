local M = {}

local ids = require("ids")
local fs = require("fs")
local buf = require("buf")
local resources = require("assistant.resources")
local rules = require("assistant.rules")
local loader = require("ui.loader")
local conversation = require("assistant.conversation")

local PromptBuilder = require("assistant.prompt_builder")
local agents = require("assistant.agents")

local CLAUDE_CACHE = ".claude-cache/"

local state = {
    resume_conversation = true,
    history = "",
    winr = -1,
    bufnr = -1,
    conversations = {},
}

M.completion = function()
    if resources.agent_name() ~= "Claude" then
        vim.notify("(assistant): unsupported agent", vim.log.levels.WARN)
        return
    end

    local _start, _end = buf.active_selection()
    if not vim.fn.isdirectory(CLAUDE_CACHE) then
        vim.fn.mkdir(CLAUDE_CACHE)
    end

    local file_id = ids.uuidv4()
    local file_name = string.format("change-%s", file_id)
    local requesting_bufnr = vim.api.nvim_get_current_buf()
    local status = vim.api.nvim_get_mode()

    local ns_id = loader.start(requesting_bufnr, _start, _end, true)

    local prompt = PromptBuilder:new()
        :with_permissions({ "write" })
        :with_strategy(agents.claude)
        :with_rules(rules.completion({
            mode = status.mode,
            write_to = CLAUDE_CACHE .. file_name,
            req_bufnr = requesting_bufnr,
            sel_start = _start,
            sel_end = _end,
        }))
        :build()

    prompt:run(function(_)
        vim.notify("󰛄 editing completed", vim.log.levels.INFO)
        vim.cmd.checktime({ mods = { silent = true } })
        local replace_start = loader.location(requesting_bufnr, ns_id)
        local offset = _end - _start + 1 -- inclusive selection end
        loader.stop(ns_id)

        local content, err = fs.read(CLAUDE_CACHE .. file_name)
        if err ~= nil or content == nil then
            vim.notify(err or "(assistant): cannot read Claude Cache", vim.log.levels.ERROR)
            return
        end
        vim.api.nvim_buf_set_lines(
            requesting_bufnr,
            replace_start,
            replace_start + offset,
            false,
            vim.split(content, "\n")
        )
    end)
end

M.ask = function()
    local requesting_bufnr = vim.api.nvim_get_current_buf()
    local status = vim.api.nvim_get_mode()
    local row = vim.api.nvim_win_get_cursor(0)[1] - 1 -- 0-based for extmarks

    -- re-open existing conversation at this line if one exists
    local existing = conversation.find_by_buf_line(requesting_bufnr, row)
    if existing then
        conversation.open_by_buf_line(requesting_bufnr, row)
        return
    end

    local session_id = resources.create_conversation()

    local prompt = PromptBuilder:new()
        :with_permissions({})
        :with_strategy(agents.claude)
        :with_rules(rules.ask({ req_bufnr = requesting_bufnr, mode = status.mode, cursor_row = row }))
        :build()

    local on_submit = function(task)
        local context = resources.active(requesting_bufnr)

        prompt:set_task(task .. "\n" .. context)
        prompt:run(function(response)
            conversation.push_message(session_id, response, "claude")
            vim.notify("(assistant): claude has answered your question!")
        end)
    end

    conversation.create_conversation(session_id, requesting_bufnr, row, on_submit)
end

return M
