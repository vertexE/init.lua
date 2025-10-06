local M = {}

local buf = require("buf")
local resources = require("assistant.resources")
local textarea = require("ui.textarea")
local loader = require("ui.loader")
local parsers = require("assistant.parsers")

local CMD_PREFIX = "<command>"
local CMD_POSTFIX = "</command>"

local prompt_agent = function(prompt, resolve)
    require("CopilotChat").ask(prompt, {
        headless = true,
        callback = function(msg)
            resolve(msg.content)
        end,
    })
end

M.generate = function()
    local requesting_bufnr = vim.api.nvim_get_current_buf()
    local status = vim.api.nvim_get_mode()
    local should_replace = status.mode == "v" or status.mode == "V" or status.mode == "^V"
    local sel_start, sel_end = buf.active_selection()
    local knowledge = resources.active()
    local prompt_header = string.format(
        [[
<rules>
- you must always respond in code.
- if you want to include an explanation, you MUST use comments.
- use the data in the <context> tags to inform your decisions
- for replace mode, only re-create code in the tag <active-selection>, the rest of the data in <context> is for reference
- for insert mode, all code in <context> is only for reference, do not include in output
- we're in %s mode, 
</rules>
    ]],
        should_replace and "replace" or "insert"
    )
    prompt_header = prompt_header .. knowledge .. "\n\n" .. "/COPILOT_GENERATE"

    local _start, _end
    if should_replace then
        _start, _end = sel_start, sel_end
    else
        local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
        _start, _end = row, row
    end

    textarea.open({ prompt = "  Generate" }, function(input)
        if input == nil or #input == 0 then
            return
        end
        local ns_id = loader.start(requesting_bufnr, _start, _end, should_replace)
        local prompt_cmd = CMD_PREFIX .. vim.fn.join(input, "\n") .. CMD_POSTFIX
        prompt_agent(prompt_header .. prompt_cmd, function(response)
            local lines = vim.split(parsers.select_content(response), "\n")
            loader.stop(ns_id)
            if should_replace then
                vim.api.nvim_buf_set_lines(requesting_bufnr, _start - 1, _end, false, lines)
            else
                vim.api.nvim_buf_set_lines(requesting_bufnr, _start, _start, false, lines)
            end
        end)
    end)
end

return M
