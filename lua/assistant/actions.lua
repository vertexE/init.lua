local M = {}

local ids = require("ids")
local fs = require("fs")
local buf = require("buf")
local resources = require("assistant.resources")
local rules = require("assistant.rules")
local request = require("assistant.request")
local inline = require("ui.inline")
local loader = require("ui.loader")
local parsers = require("assistant.parsers")
local plan = require("assistant.plan")
local conversation = require("assistant.conversation")

local PromptBuilder = require("assistant.prompt_builder")
local agents = require("assistant.agents")

local CMD_PREFIX = "<user-request>"
local CMD_POSTFIX = "</user-request>\n"
local CLAUDE_PLANS_DIR = "~/.claude/plans"
local CLAUDE_CACHE = ".claude-cache/"

--- @alias llm.Action "generate"|"ask"|"modify"|"plan"

local state = {
    --- @type llm.Action|nil
    active_action = nil,
    resume_conversation = true,
    history = "",
    winr = -1,
    bufnr = -1,
    conversations = {},
}

--- @class llm.PromptCfg
--- @field session_id ?string
--- @field resume ?boolean

--- prompt selected agent
--- @param prompt string
--- @param resolve fun(result:string)
--- @param opts ?llm.PromptCfg
local prompt_agent = function(prompt, resolve, opts)
    -- TODO: eventually remove Copilot support as I now only use claude
    if resources.agent_name() == "Copilot" then
        require("CopilotChat").ask(prompt, {
            headless = true,
            callback = function(msg)
                resolve(msg.content)
            end,
        })
    elseif resources.agent_name() == "Claude" then
        local cmd = { "claude", "-p", prompt, "--allowedTools", '"Bash(git diff:*)"' }
        if state.active_action == "ask" and state.resume_conversation then
            table.insert(cmd, "--continue")
        elseif state.active_action == "generate" or state.active_action == "modify" then
            table.insert(cmd, "--permission-mode")
            table.insert(cmd, "acceptEdits")
        elseif state.active_action == "plan" then
            table.insert(cmd, "--permission-mode")
            table.insert(cmd, "plan")
            table.insert(cmd, "--output-format")
            table.insert(cmd, "json")
        end

        if opts and opts.session_id and opts.resume then
            table.insert(cmd, "--resume")
            table.insert(cmd, opts.session_id)
        elseif opts and opts.session_id then
            table.insert(cmd, "--session-id")
            table.insert(cmd, opts.session_id)
        end

        vim.system(
            cmd,
            { text = true },
            vim.schedule_wrap(function(result)
                if result.stdout and #result.stdout > 0 then
                    resolve(result.stdout)
                    -- TODO: setup a way to auto show the edits in a new tab and we go through and accept/deny them...
                    -- maybe we can take advantage of gitsigns and open a new tab and show the diff?
                    -- or I can use the undotree?
                end
            end)
        )
    end
end

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

    -- TODO: legacy
    state.active_action = "generate"

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

--- @deprecated
M.create_plan = function()
    if resources.agent_name() ~= "Claude" then
        vim.notify("(assistant): unsupported agent", vim.log.levels.WARN)
        return
    end
    local session_id = ids.uuidv4()

    state.active_action = "plan"
    local requesting_bufnr = vim.api.nvim_get_current_buf()
    local status = vim.api.nvim_get_mode()
    local prompt_header = rules.plan({ mode = status.mode, req_bufnr = requesting_bufnr })
    plan.create_plan(function(goal, _plan)
        vim.api.nvim_exec_autocmds("User", { pattern = "StatusRedraw" })
        prompt_agent(CMD_PREFIX .. goal .. CMD_POSTFIX .. prompt_header, function(_)
            _plan.status = "reviewable"
            _plan.session_id = session_id

            vim.notify(string.format("(assistant): plan is ready for review"), vim.log.levels.INFO)
            vim.cmd.tabnew()
            vim.cmd.edit({ args = { fs.last_modified_file_in_dir(CLAUDE_PLANS_DIR) } })

            vim.schedule(function()
                local bufnr = vim.api.nvim_get_current_buf()
                vim.keymap.set("n", "q", function()
                    vim.cmd.tabclose()
                end, { buffer = bufnr })

                vim.keymap.set("n", "<enter>", function()
                    vim.notify("(assistant): approved plan!")
                    _plan.status = "executable"
                    vim.api.nvim_exec_autocmds("User", { pattern = "StatusRedraw" })
                    vim.cmd.tabclose()
                end, { buffer = bufnr })
            end)
        end, { session_id = session_id })
    end)
end

--- execute the active plan
--- @deprecated
M.execute_plan = function()
    if resources.agent_name() ~= "Claude" then
        vim.notify("(assistant): unsupported agent", vim.log.levels.WARN)
        return
    end

    state.active_action = "modify" -- uses the same permissions
    local selected_plan = plan.active_plan()
    if not selected_plan then
        vim.notify("(assistant) no such plan exists", vim.log.levels.ERROR)
        return
    end

    if selected_plan.status ~= "executable" then
        vim.notify("(assistant) plan not in executable state", vim.log.levels.INFO)
        return
    end

    selected_plan.status = "executing"
    vim.api.nvim_exec_autocmds("User", { pattern = "StatusRedraw" })
    vim.notify(string.format("(assistant): starting plan!"))
    prompt_agent("execute the plan", function(_)
        vim.notify("(assistant): plan completed")
        selected_plan.status = "completed"
        vim.cmd.checktime({ mods = { silent = true } })
        vim.api.nvim_exec_autocmds("User", { pattern = "StatusRedraw" })
    end, { session_id = selected_plan.session_id, resume = true })
end

--- @deprecated prefer completion instead
M.generate = function()
    state.active_action = "generate"
    local requesting_bufnr = vim.api.nvim_get_current_buf()
    -- local requesting_file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(requesting_bufnr), ":.")
    local status = vim.api.nvim_get_mode()
    local should_replace = status.mode == "v" or status.mode == "V" or status.mode == "^V"
    local sel_start, sel_end = buf.active_selection()
    local prompt_header = rules.generate({ mode = status.mode, req_bufnr = requesting_bufnr })

    local _start, _end
    if should_replace then
        _start, _end = sel_start, sel_end
    else
        local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
        _start, _end = row, row
    end

    inline.cursor(
        { title = { string.format("%s Generate", resources.agent_icon()), "MiniIconsPurple" } },
        function(input)
            if input == nil or #input == 0 then
                return
            end

            local req_id = request.start(resources.active_files())
            vim.api.nvim_exec_autocmds("User", { pattern = "StatusRedraw" })
            local ns_id = loader.start(requesting_bufnr, _start, _end, should_replace)
            vim.defer_fn(function() -- timeout
                loader.stop(ns_id)
                request.complete(req_id)
            end, 30000)
            local prompt_cmd = CMD_PREFIX .. vim.fn.join(input, "\n") .. CMD_POSTFIX

            prompt_agent(prompt_header .. prompt_cmd, function(response)
                request.complete(req_id)
                if resources.agent_name() == "Claude" then
                    vim.notify("󰛄 editing completed", vim.log.levels.INFO)
                    vim.cmd.checktime({ mods = { silent = true } })
                    loader.stop(ns_id)
                    return
                end

                local lines = vim.split(parsers.select_content(response), "\n")
                loader.stop(ns_id)
                if should_replace then
                    vim.api.nvim_buf_set_lines(requesting_bufnr, _start - 1, _end, false, lines)
                else
                    vim.api.nvim_buf_set_lines(requesting_bufnr, _start, _start, false, lines)
                end
            end)
        end
    )
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
