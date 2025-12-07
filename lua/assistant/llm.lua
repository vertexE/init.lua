local M = {}

local buf = require("buf")
local resources = require("assistant.resources")
local prompts = require("assistant.prompts")
local request = require("assistant.request")
local inline = require("ui.inline")
local loader = require("ui.loader")
local parsers = require("assistant.parsers")
local splits = require("ui.splits")

local CMD_PREFIX = "<user-request>"
local CMD_POSTFIX = "</user-request>"

--- @alias llm.Action "generate"|"ask"|"modify" -- and maybe add "plan" one day?

local state = {
    --- @type llm.Action|nil
    active_action = nil,
    resume_conversation = true,
    history = "",
    winr = -1,
    bufnr = -1,
}

--- prompt selected agent
--- @param prompt string
--- @param resolve fun(result:string)
local prompt_agent = function(prompt, resolve)
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

M.generate = function()
    state.active_action = "generate"
    local requesting_bufnr = vim.api.nvim_get_current_buf()
    local requesting_file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(requesting_bufnr), ":.")
    local status = vim.api.nvim_get_mode()
    local should_replace = status.mode == "v" or status.mode == "V" or status.mode == "^V"
    local sel_start, sel_end = buf.active_selection()
    local prompt_header = prompts.generate({ mode = status.mode, req_bufnr = requesting_bufnr })

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

            local req_id = request.start({ requesting_file })
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

M.modify = function()
    state.active_action = "modify"
    if resources.agent_name() ~= "Claude" then
        vim.notify("(assistant) modify is only supported by Claude", vim.log.levels.WARN)
        return
    end
    local requesting_bufnr = vim.api.nvim_get_current_buf()
    local status = vim.api.nvim_get_mode()
    local prompt_header = prompts.modify({ mode = status.mode, req_bufnr = requesting_bufnr })

    inline.cursor({ title = { string.format("%s Ask", resources.agent_icon()), "MiniIconsPurple" } }, function(input)
        if input == nil or #input == 0 then
            return
        end
        local prompt_cmd = CMD_PREFIX .. vim.fn.join(input, "\n") .. CMD_POSTFIX

        local req_id = request.start(resources.active_files())
        prompt_agent(prompt_header .. prompt_cmd, function(_)
            -- TODO: add in the unlock files here...
            vim.notify("󰛄 feature completed", vim.log.levels.INFO)
            vim.cmd.checktime({ mods = { silent = true } })
            request.complete(req_id)
        end)
    end)
end

M.ask = function()
    state.active_action = "ask"
    local knowledge = resources.active()
    local prompt_header = prompts.ask()
    inline.cursor({ title = { string.format("%s Ask", resources.agent_icon()), "MiniIconsPurple" } }, function(input)
        if input == nil or #input == 0 then
            return
        end
        local prompt = vim.fn.join(input, "\n")
        prompt_agent(
            ((resources.agent_name() == "Claude" and state.resume_conversation) and "" or prompt_header)
                .. "<question>"
                .. prompt
                .. "</question>"
                .. knowledge
                .. (resources.agent_name() == "Copilot" and state.history or ""),
            function(response)
                if not vim.api.nvim_win_is_valid(state.winr) then
                    local bufnr, winr = splits.horizontal(response, {
                        enter = true,
                        height = 0.22,
                        wo = { number = false, wrap = true },
                        split = "below",
                        bo = { filetype = "markdown" },
                    })
                    state.winr = winr
                    state.bufnr = bufnr

                    vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
                        group = vim.api.nvim_create_augroup("user.copilot.ask", { clear = true }),
                        buffer = bufnr,
                        once = true,
                        callback = function()
                            state.history = ""
                            state.resume_conversation = true
                        end,
                        desc = "clear history on buf delete",
                    })
                else
                    vim.api.nvim_buf_set_lines(state.bufnr, 0, -1, false, vim.split(response, "\n"))
                end

                if resources.agent_name() == "Copilot" then
                    state.history = "<previous-question>"
                        .. prompt
                        .. "</previous-question>"
                        .. "<copilot-response>"
                        .. response
                        .. "</copilot-response>"
                        .. state.history
                elseif resources.agent_name() == "Claude" then
                    state.resume_conversation = true
                end
            end
        )
    end)
end

return M
