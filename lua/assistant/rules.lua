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

local codex = {
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
- the selected code is in the current file
</context>
<rules>
- read the code in the selection and any comments inside it, then complete or rewrite that block accordingly
- only read the current file for this task
- only produce the replacement for the selected block
- do not edit any other file contents
- do not respond with markdown, explanations, or chat text
- write the replacement block exactly to @%s
- if the replacement should be empty, write an empty file to @%s
- preserve indentation so the replacement can be inserted directly back into the buffer
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

    --- @param ctx prompt.context
    --- @return string
    worktree = function(ctx)
        local file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(ctx.req_bufnr), ":.")

        return string.format(
            [[
<context>
- current file: @%s
- current cursor row: %d
</context>
<rules>
- attempt to complete the user's request to the best of your ability and knowledge
- use the request and codebase to inform your decisions as much as possible, explore where you need to
- if something is unknown, add a comment in the codebase where you are unsure and keep working
- if you think you worked on something without enough context, also leave a comment there
- always choose the simplest approach that solves the problem, do not go outside the scope of the request unless absolutely necessary
- ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.
- only modify what you touch, do not refactor / modify outside of the request
- do not create commits
- once you understand how to complete the task, begin the work -- you are in headless mode and the user cannot respond to questions
</rules>
<on-completion>
your response after completing all the work should be something like
```
successfully completed <summary of requested task>. Assumptions
- assumption 1
- assumption 2
- assumption 3
```
</on-completion>
            ]],
            file,
            ctx.cursor_row or -1
        )
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

    --- @param ctx prompt.context
    --- @return string
    worktree = function(ctx)
        local file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(ctx.req_bufnr), ":.")

        return string.format(
            [[
<context>
- current file: @%s
- current cursor row: %d
</context>
<rules>
- attempt to complete the user's request to the best of your ability and knowledge
- use the request and codebase to inform your decisions as much as possible, explore where you need to
- if something is unknown, add a comment in the codebase where you are unsure and keep working
- if you think you worked on something without enough context, also leave a comment there
- always choose the simplest approach that solves the problem, do not go outside the scope of the request unless absolutely necessary
- ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.
- only modify what you touch, do not refactor / modify outside of the request
- do not create commits
- once you understand how to complete the task, begin the work -- you are in headless mode and the user cannot respond to questions
</rules>
<on-completion>
your response after completing all the work should be something like
```
successfully completed <summary of requested task>. Assumptions
- assumption 1
- assumption 2
- assumption 3
```
</on-completion>
            ]],
            file,
            ctx.cursor_row or -1
        )
    end,
}

--- @param ctx prompt.context
--- @return string
M.completion = function(ctx)
    if resources.agent_name() == "Codex" then
        return codex.completion(ctx)
    elseif resources.agent_name() == "Claude" then
        return claude.completion(ctx)
    end

    vim.notify("unsupported agent", vim.log.levels.WARN)
    return ""
end

--- @param ctx prompt.context
--- @return string
M.ask = function(ctx)
    if resources.agent_name() == "Codex" then
        return codex.ask(ctx)
    elseif resources.agent_name() == "Claude" then
        return claude.ask(ctx)
    end

    vim.notify("unsupported agent", vim.log.levels.WARN)
    return ""
end

--- @param ctx prompt.context
--- @return string
M.worktree = function(ctx)
    if resources.agent_name() == "Codex" then
        return codex.worktree(ctx)
    elseif resources.agent_name() == "Claude" then
        return claude.worktree(ctx)
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
