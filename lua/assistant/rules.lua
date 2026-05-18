local M = {}

local resources = require("assistant.resources")
--- @class prompt.context
--- @field mode string
--- @field req_bufnr integer
--- @field input ?string
--- @field sel_start ?integer
--- @field sel_end ?integer
--- @field cursor_row ?integer
--- @field write_to ?string file path to write to instead

local copilot = {
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
    ask = function(ctx)
        local file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(ctx.req_bufnr), ":.")
        return string.format(
            [[
<rules>
- you are current in the file @%s
- the 0-indexed cursor position is %d 
- a -1 index means cursor position is unknown
- answer the following question(s)
- keep it short, to the point, and use markdown standards.
- instead of suggesting any edits, provide examples
- prefer explaining *why* over *what*
- use `files` tag as hints of which files to read to answer the question
</rules>
        ]],
            file,
            ctx.cursor_row or -1
        )
    end,

    --- @param ctx prompt.context
    --- @return string
    completion = function(ctx)
        local file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(ctx.req_bufnr), ":.")
        local lines = vim.api.nvim_buf_get_lines(ctx.req_bufnr, ctx.sel_start - 1, ctx.sel_end, false)

        return string.format(
            [[
<context>
- you are currently in the file @%s
- the 0-indexed cursor position is %d 
</context>
<rules>
- **CRITICAL**: Read the code in the selection, this code is in the current file. Find any code comments and attempt to complete the code as specified. 
- **CRITICAL**: ONLY READ the current file, YOU MUST WRITE THE NEW CODE BLOCK TO @%s
- **CRITICAL**: ONLY EDIT the current code block, DO NOT edit anywhere else. If the change requires imports or other edits, the user will take care of that.
- The new code block should match the same indentation level as the old code block.
- Your job is to make @%s look exactly like what we would replace `<selection>` with, so if you need to delete everything the file would be empty 
</rules>
<selection>
%s
</selection>
        ]],
            file,
            ctx.sel_start - 1,
            ctx.write_to,
            ctx.write_to,
            table.concat(lines, "\n")
        )
    end,
}

--- @param ctx prompt.context
--- @return string
M.completion = function(ctx)
    if resources.agent_name() ~= "Claude" then
        vim.notify("unsupported agent", vim.log.levels.WARN)
        return ""
    end

    return claude.completion(ctx)
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
