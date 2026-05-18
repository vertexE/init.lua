local M = {}

local buf = require("buf")
local ids = require("ids")
local request = require("assistant.request")

local diagnostics = function(bufnr)
    local buf_name = vim.api.nvim_buf_get_name(bufnr or 0)
    local file_name = vim.fn.fnamemodify(buf_name, ":t")
    local diagnostics = vim.diagnostic.get(bufnr or 0)
    return vim.fn.join(
        vim.iter(diagnostics)
            :map(function(diagnostic)
                return string.format("%s:%d %s", file_name, diagnostic.lnum, diagnostic.message)
            end)
            :totable(),
        "\n"
    )
end

--- this really is only to track which resources are on/off, that's it!

--- @type table<resourceType,boolean>
local resources = {
    blocks = false,
    selection = false,
    git_diff = false,
    lsp_diagnostics = false,
    buffers = false,
}

--- @alias llm.Agent "Claude"|"Codex"

local resource_state = {
    --- @type table<string>
    blocks = {},
    --- @type table<integer,boolean>
    active_bufs = {},
    --- @type llm.Agent -- default agent to use for inline requests
    agent = "Claude",
    --- @type table<string> list of conversation IDs to include in context
    conversations = {},
}

local active_bufs_summary = function()
    local count = 0
    local first = ""
    for _buf, is_active in pairs(resource_state.active_bufs) do
        if is_active then
            count = count + 1
        end
        if #first == 0 then
            local buf_name = vim.api.nvim_buf_get_name(_buf)
            first = vim.fn.fnamemodify(buf_name, ":t")
        end
    end
    return count == 1 and first or (count > 1 and string.format("%s..+%d", first, count - 1) or "..")
end

--- comment
--- @param req llm.request
--- @return table<table<string>>
local render_request = function(req)
    local file = vim.fn.fnamemodify(req.files[1], ":t")

    return {
        { file, "Comment" },
        { #req.files > 1 and string.format("..+%d", #req.files - 1) or "", "Comment" },
    }
end

--- @return table<table<table>>>
M.locked_files = function()
    local requests = request.active_requests()
    local v_lines = {}

    for _, req in pairs(requests) do
        table.insert(v_lines, render_request(req))
    end
    return v_lines
end

M.agent_icon = function()
    return resource_state.agent == "Codex" and " " or "󰛄 "
end

--- @return llm.Agent
M.agent_name = function()
    return resource_state.agent
end

M.agent = function()
    return {
        {
            resource_state.agent == "Codex" and "  " or " 󰛄 ",
            "MiniIconsGreen",
        },
        { string.format(" %s", resource_state.agent), "Comment" },
    }
end

M.status = function()
    local v_lines = {}
    table.insert(v_lines, {
        { " 󰒉 ", resources.selection and "MiniIconsRed" or "Comment" },
        { " - visual lines", "Comment" },
    })
    table.insert(v_lines, {
        { "  ", resources.lsp_diagnostics and "MiniIconsRed" or "Comment" },
        { " - diagnostics", "Comment" },
    })
    table.insert(v_lines, {
        { "  ", resources.git_diff and "MiniIconsRed" or "Comment" },
        { " - git diff", "Comment" },
    })
    table.insert(v_lines, {
        { "  ", resources.blocks and "MiniIconsRed" or "Comment" },
        { string.format(" - blocks %d", #resource_state.blocks), "Comment" },
    })
    table.insert(v_lines, {
        { "  ", resources.buffers and "MiniIconsRed" or "Comment" },
        { string.format(" - %s", active_bufs_summary()), "Comment" },
    })
    return v_lines
end

-- format selection lines with XML tags. if lines are provided, use them; otherwise query buffer
local sel_lines = function(bufnr, sel_start, sel_end, lines)
    if not lines then
        lines = vim.api.nvim_buf_get_lines(bufnr, sel_start - 1, sel_end, false)
    end
    local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
    return string.format("<active-selection filetype='%s'>\n", ft)
        .. table.concat(lines, "\n")
        .. "\n</active-selection>"
end

--- @param bufnr ?integer
local selection = function(bufnr)
    bufnr = bufnr or 0
    local sel_start, sel_end = buf.active_selection()
    return sel_lines(bufnr, sel_start, sel_end)
end

--- @alias resourceType "blocks"|"selection"|"lsp_diagnostics"|"git_diff"|"buffers"|"conversations"

---@param rt resourceType
M.toggle = function(rt)
    resources[rt] = not resources[rt]
end

--- @class resourceContext
--- @field sel_start integer
--- @field sel_end integer
--- @field sel_lines ?string[]

--- all active resources
--- @param bufnr ?integer
--- @param ctx ?resourceContext
--- @return string
M.active = function(bufnr, ctx)
    local knowledge = ""
    if resources.selection and ctx then
        -- use captured lines if provided, otherwise query buffer
        knowledge = knowledge .. sel_lines(bufnr, ctx.sel_start, ctx.sel_end, ctx.sel_lines)
    elseif resources.selection then
        knowledge = knowledge .. selection(bufnr)
    end
    if resources.git_diff then
        knowledge = knowledge .. "\n include git diff in context"
    end
    if resources.lsp_diagnostics then
        knowledge = knowledge .. "<diagnostics>" .. diagnostics(bufnr) .. "</diagnostics>"
    end
    if resources.blocks then
        knowledge = knowledge .. "<code-segments>" .. vim.fn.join(resource_state.blocks, "\n") .. "</code-segments>"
    end
    if resources.buffers then
        local files = "\n"
        for _bufnr, _ in pairs(resource_state.active_bufs) do
            local file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(_bufnr), ":.")
            files = files .. file .. "\n"
        end
        knowledge = knowledge .. "\n<files>\n" .. files .. "</files>\n"
    end
    return knowledge
end

M.add_block = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local buf_name = vim.api.nvim_buf_get_name(bufnr)
    local file_name = vim.fn.fnamemodify(buf_name, ":t")
    local content = buf.active_selection_lines()
    table.insert(resource_state.blocks, string.format("<%s>\n%s\n</%s>", file_name, content, file_name))
    vim.notify("added block!", vim.log.levels.INFO, {})
end

M.clear_blocks = function()
    resource_state.blocks = {}
    vim.notify("clear blocks!", vim.log.levels.INFO, {})
end

M.select_buffers = function()
    require("snacks").picker.pick("buffers", {
        filter = {
            filter = function(item)
                return string.find(item.file, "Scratch") == nil
            end,
        },
        confirm = function(picker)
            local items = picker:selected()
            resource_state.active_bufs = {}
            for _, item in ipairs(items) do
                resource_state.active_bufs[item.buf] = true
            end
            vim.notify(string.format("Set %d active buffer(s)", #items), vim.log.levels.INFO)
        end,
    })
end

--- all buffers set to active + the current buffer
--- @return string[]
M.active_files = function()
    local files = {}
    local open_bufnr = vim.api.nvim_get_current_buf()
    for _buf, _ in pairs(resource_state.active_bufs) do
        if _buf ~= open_bufnr then
            local file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(_buf), ":.")
            table.insert(files, file)
        end
    end
    local file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(open_bufnr), ":.")
    table.insert(files, file)

    return files
end

M.next_agent = function()
    if resource_state.agent == "Claude" then
        resource_state.agent = "Codex"
        return
    end

    resource_state.agent = "Claude"
end

M.create_conversation = function()
    local conversation_id = ids.uuidv4()
    table.insert(resource_state.conversations, conversation_id)
    return conversation_id
end

return M
