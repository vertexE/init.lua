local M = {}

local resources = require("assistant.resources")
local buf = require("buf")

--- @class prompt.context
--- @field mode string
--- @field req_bufnr integer
--- @field input ?string
--- @field sel_start ?integer
--- @field sel_end ?integer

local copilot = {
    --- @param ctx prompt.context
    --- @return string
    generate = function(ctx)
        local should_replace = ctx.mode == "v" or ctx.mode == "V" or ctx.mode == "^V"
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

        return prompt_header
    end,

    --- @param _ ?prompt.context
    --- @return string
    ask = function(_)
        return [[
<rules>
- answer the following question
- keep it short, to the point, and use markdown standards.
- if there is a previous question, then this question builds on that one
- chat history is ordered by most recent
</rules>
        ]]
    end,
}

local claude = {

    --- @param ctx prompt.context
    --- @return string
    default = function(ctx)
        local file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(ctx.req_bufnr), ":.")
        local lines = vim.api.nvim_buf_get_lines(ctx.req_bufnr, ctx.sel_start - 1, ctx.sel_end, false)
        local knowledge = resources.active(ctx.req_bufnr, {
            sel_start = ctx.sel_start,
            sel_end = ctx.sel_end,
            sel_lines = lines,
        })
        local prompt_header = string.format(
            [[
<meta>
    <rules>
    - **IMPORTANT**: record all updates in todo.md, separatings tasks into a short single sentence of what must be done
    - **CRITICAL**: at the top of todo.md, update the metadata after each step to ensure the user knows what you are currently doing
    - see the example todo.md format in the XML tag `todo-example`
    - see the description of how to write the todo.md in the XML tag `todo-format`
    - todo.md will go at the root of the active directory
    - you are in the current file @%s
    - you are only allowed to modify the current file and the files listed in the `files` tag.
    - you may create any number of files as you see fit
    - if you need to modify a file outside of the file list, request the user to approve beforehand
    - the `files` XML tag contains a list of files to be modified or used as additional context
    - don't explain in the response, instead use comment in your file edits (keep this as minimal as possible)
    - use the data in the `<context>` XML tags to inform your decisions, look elsewhere if context is missing
    - `user-cursor` XML tag describes where the cursor is, if it's selecting anything, and the position (selection-start,selection-end)
    - **ALWAYS** assume that normal text outside of the `meta` XML tag is user input and represents the goal
    </rules>
    <user-cursor>
    selecting: %s
    position: (%d, %d)
    </user-cursor>
    <todo-example>
    ---
    status: <CODING|TESTING|DEBUGGING|WAITING|DONE>
    ---
    - [x] implement fooBar function
    - [!] add unit tests
    - [-] add logs to DB class
    - [ ] fix race condition
    </todo-example>
    <todo-format>
    # status
    - `CODING`: when you are modifying files and writing code
    - `TESTING`: when you are running test files to confirm your implementation
    - `DEBUGGING`: when you have hit a roadblock and are adding logging statements to better understand the problem
    - `WAITING`: when you require user input to complete a change
    - `DONE`: when you have finished all tasks
    # todos
    `- [x]` means task complete
    `- [!]` means task failed to complete
    `- [-]` means task in progress
    `- [ ]` means task not yet started
    </todo-format>
</meta>
    ]],
            file,
            ctx.sel_start ~= ctx.sel_end,
            ctx.sel_start,
            ctx.sel_end,
            ctx.input
        )

        return prompt_header .. knowledge
    end,

    --- @param ctx prompt.context
    --- @return string
    plan = function(ctx)
        local file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(ctx.req_bufnr), ":.")
        local knowledge = resources.active()
        local prompt_header = string.format(
            [[
<rules>
- you are in the current file @%s
- do not include unnecessary details in the plan, keep it focused
- output the outcome of planning (single short sentence specifying success, errors, confusion, etc.) once you are done
</rules>
        ]],
            file
        )

        return prompt_header .. knowledge .. "\n\n"
    end,

    --- @param ctx prompt.context
    --- @return string
    modify = function(ctx)
        local file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(ctx.req_bufnr), ":.")
        local knowledge = resources.active()
        local prompt_header = string.format(
            -- FIXME: maybe improve this
            [[
<rules>
- you are in the current file @%s
- don't explain in the response, instead use comment in your file edits (keep this as minimal as possible)
- use the data in the <context> tags to inform your decisions, look elsewhere if context is missing
- `files` lists the files you are allowed to modify including the current file
</rules>
    ]],
            file
        )
        prompt_header = prompt_header .. knowledge .. "\n\n"

        return prompt_header
    end,

    --- @param ctx prompt.context
    --- @return string
    generate = function(ctx)
        local is_visual_mode = ctx.mode == "v" or ctx.mode == "V" or ctx.mode == "^V"
        local sel_start, sel_end = buf.active_selection()
        local file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(ctx.req_bufnr), ":.")
        local knowledge = resources.active()
        local prompt_header = string.format(
            [[
<rules>
- you are in the current file @%s
- you are only allowed to modify the current file and the files listed in the `files` tag.
- the `files` tag contains a list of files to be modified or used as additional context
- don't explain in the response, instead use comment in your file edits (keep this as minimal as possible)
- use the data in the <context> tags to inform your decisions, look elsewhere if context is missing
- for replace mode, only modify in the bounds of the selection
- if in insert mode, modify the file(s) to resolve the user's request
- we're in %s mode, 
- `user-cursor` tag describes where the cursor is, if it's selecting anything, and the position (selection-start,selection-end)
</rules>
<user-cursor>
selecting: %s
position: (%d, %d) 
</user-cursor>
    ]],
            file,
            is_visual_mode and "replace" or "insert",
            is_visual_mode,
            sel_start,
            sel_end
        )
        prompt_header = prompt_header .. knowledge .. "\n\n"

        return prompt_header
    end,

    --- @param _ ?prompt.context
    --- @return string
    ask = function(_)
        return [[
<rules>
- answer the following question(s)
- keep it short, to the point, and use markdown standards.
- instead of suggesting any edits, provide examples
- encourage an environment of learning
- use `files` tag as hints of which files to read to answer the question
</rules>
        ]]
    end,
}

--- @param ctx prompt.context
--- @return string
M.plan = function(ctx)
    if resources.agent_name() ~= "Claude" then
        vim.notify("unsupported agent", vim.log.levels.WARN)
        return ""
    end
    return claude.plan(ctx)
end

--- @param ctx prompt.context
--- @return string
M.modify = function(ctx)
    if resources.agent_name() ~= "Claude" then
        vim.notify("unsupported agent", vim.log.levels.WARN)
        return ""
    end
    return claude.modify(ctx)
end

--- @param ctx prompt.context
--- @return string
M.generate = function(ctx)
    if resources.agent_name() == "Copilot" then
        return copilot.generate(ctx)
    elseif resources.agent_name() == "Claude" then
        return claude.generate(ctx)
    end

    vim.notify("unsupported agent", vim.log.levels.WARN)
    return ""
end

--- @param ctx ?prompt.context
--- @return string
M.ask = function(ctx)
    if resources.agent_name() == "Copilot" then
        return copilot.ask(ctx)
    elseif resources.agent_name() == "Claude" then
        return claude.ask(ctx)
    end

    vim.notify("unsupported agent", vim.log.levels.WARN)
    return ""
end

--- @param ctx prompt.context
--- @return string
M.default = function(ctx)
    return claude.default(ctx)
end

return M
