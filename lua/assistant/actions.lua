local M = {}

local ids = require("ids")
local fs = require("fs")
local buf = require("buf")
local resources = require("assistant.resources")
local rules = require("assistant.rules")
local loader = require("ui.loader")
local inline = require("ui.inline")
local conversation = require("assistant.conversation")
local worktrees = require("assistant.worktrees")

local PromptBuilder = require("assistant.prompt_builder")
local agents = require("assistant.agents")

local AGENT_CACHE = ".agent-cache/"

local state = {
    resume_conversation = true,
    history = "",
    winr = -1,
    bufnr = -1,
    conversations = {},
}

local provider_strategy = function()
    return resources.agent_name() == "Codex" and agents.codex or agents.claude
end

local provider_message_source = function()
    return resources.agent_name() == "Codex" and "codex" or "claude"
end

M.completion = function()
    local agent_name = resources.agent_name()
    if agent_name ~= "Claude" and agent_name ~= "Codex" then
        vim.notify("(assistant): unsupported agent", vim.log.levels.WARN)
        return
    end

    local _start, _end = buf.active_selection()
    if not vim.fn.isdirectory(AGENT_CACHE) then
        vim.fn.mkdir(AGENT_CACHE)
    end

    local file_id = ids.uuidv4()
    local file_name = string.format("change-%s", file_id)
    local cache_path = AGENT_CACHE .. file_name
    local requesting_bufnr = vim.api.nvim_get_current_buf()
    local status = vim.api.nvim_get_mode()

    local ns_id = loader.start(requesting_bufnr, _start, _end, true)

    local prompt = PromptBuilder:new()
        :with_permissions({ "write" })
        :with_strategy(provider_strategy())
        :with_rules(rules.completion({
            mode = status.mode,
            write_to = cache_path,
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

        local content, err = fs.read(cache_path)
        if err ~= nil or content == nil then
            vim.notify(
                err or string.format("(assistant): %s did not write completion output", agent_name),
                vim.log.levels.ERROR
            )
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

    local conversation_id = resources.create_conversation()
    local provider = provider_message_source()
    local session_id = resources.agent_name() == "Claude" and ids.uuidv4() or nil

    local prompt = PromptBuilder:new()
        :with_permissions({})
        :with_strategy(provider_strategy())
        :with_rules(rules.ask({ req_bufnr = requesting_bufnr, mode = status.mode, cursor_row = row }))
        :with_session_id(session_id)
        :build()

    local on_submit = function(task)
        local context = resources.active(requesting_bufnr)

        prompt:set_task(task .. "\n" .. context)
        prompt:run(function(response)
            conversation.push_message(conversation_id, response, provider)
            vim.notify(string.format("(assistant): %s has answered your question!", provider))
        end)
    end

    conversation.create_conversation(conversation_id, requesting_bufnr, row, provider, on_submit)
end

M.add_worktree_task = function()
    local requesting_bufnr = vim.api.nvim_get_current_buf()
    local row = vim.api.nvim_win_get_cursor(0)[1] - 1

    inline.cursor({ title = "Worktree task" }, function(lines)
        local request = table.concat(lines, "\n"):gsub("^%s*(.-)%s*$", "%1")
        if #request == 0 then
            return
        end

        worktrees.add(request, { req_bufnr = requesting_bufnr, cursor_row = row })
    end)
end

M.list_worktree_tasks = function()
    require("assistant.picker.worktrees").open()
end

return M
