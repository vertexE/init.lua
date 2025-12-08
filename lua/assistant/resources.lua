local M = {}

local buf = require("buf")
local tbl = require("tbl")
local floats = require("ui.floats")
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

--- @alias llm.Agent"Copilot"|"Claude"

local resource_state = {
    --- @type table<string>
    blocks = {},
    --- @type table<integer,boolean>
    active_bufs = {},
    --- @type llm.Agent -- default agent to use for inline requests
    agent = "Copilot",
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
    return resource_state.agent == "Copilot" and " " or "󰛄 "
end

--- @return llm.Agent
M.agent_name = function()
    return resource_state.agent
end

M.agent = function()
    return {
        {
            resource_state.agent == "Copilot" and " " or "󰛄 ",
            "MiniIconsGreen",
        },
        { string.format(" %s", resource_state.agent), "Comment" },
    }
end

M.status = function()
    local v_lines = {}
    table.insert(v_lines, {
        { "󰒉 ", resources.selection and "MiniIconsRed" or "Comment" },
        { " - visual lines", "Comment" },
    })
    table.insert(v_lines, {
        { " ", resources.lsp_diagnostics and "MiniIconsRed" or "Comment" },
        { " - diagnostics", "Comment" },
    })
    table.insert(v_lines, {
        { " ", resources.git_diff and "MiniIconsRed" or "Comment" },
        { " - git diff", "Comment" },
    })
    table.insert(v_lines, {
        { " ", resources.blocks and "MiniIconsRed" or "Comment" },
        { string.format(" - blocks %d", #resource_state.blocks), "Comment" },
    })
    table.insert(v_lines, {
        { " ", resources.buffers and "MiniIconsRed" or "Comment" },
        { string.format(" - %s", active_bufs_summary()), "Comment" },
    })
    return v_lines
end

local selection = function()
    local sel_start, sel_end = buf.active_selection()
    local lines = vim.api.nvim_buf_get_lines(0, sel_start - 1, sel_end, false)
    local ft = vim.api.nvim_get_option_value("filetype", { buf = 0 })
    return string.format("<active-selection filetype='%s'>", ft) .. table.concat(lines, "\n") .. "</active-selection>"
end

--- @alias resourceType "blocks"|"selection"|"lsp_diagnostics"|"git_diff"|"buffers"

---@param rt resourceType
M.toggle = function(rt)
    resources[rt] = not resources[rt]
end

--- all active resources
--- @param bufnr ?integer
--- @return string
M.active = function(bufnr)
    local knowledge = ""
    if resources.selection then
        knowledge = knowledge .. selection()
    end
    if resources.git_diff then
        knowledge = knowledge
            .. (
                resource_state.agent == "Claude" and "\n include git diff in context"
                or "\n #gitdiff:unstaged #gitdiff:staged"
            )
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
            local file = resource_state.agent == "Claude"
                    and vim.fn.fnamemodify(vim.api.nvim_buf_get_name(_bufnr), ":.")
                or string.format("#buffer:%d ", _bufnr)
            files = files .. file .. "\n"
        end
        if resource_state.agent == "Claude" then
            knowledge = knowledge .. "\n<files>\n" .. files .. "</files>\n"
        else
            knowledge = knowledge .. "\n" .. files
        end
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

--- @type table<integer,integer> 1 based index map
local line_to_bufnr = {}
local MAX_LINES = 100

local draw = function(bufnr)
    local ns = vim.api.nvim_create_namespace("user.assistant.select_buffers")
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, tbl.rep({}, " ", MAX_LINES))

    local line = 1
    for _, _buf in ipairs(vim.api.nvim_list_bufs()) do
        local name = vim.api.nvim_buf_get_name(_buf)
        local display_name = name ~= "" and vim.fn.fnamemodify(name, ":.") or ""
        if
            vim.api.nvim_buf_is_loaded(_buf)
            and vim.api.nvim_get_option_value("buflisted", { buf = _buf })
            and #display_name > 0
        then
            local toggled_on = resource_state.active_bufs[_buf]
            vim.api.nvim_buf_set_lines(bufnr, line - 1, line - 1, false, { "   " .. display_name })
            vim.api.nvim_buf_set_extmark(bufnr, ns, line - 1, 0, {
                virt_text_pos = "overlay",
                virt_text = {
                    toggled_on and { "  ", "MiniIconsOrange" } or { "  ", "@constant" },
                    { display_name, "@constant" },
                },
            })
            line_to_bufnr[line] = _buf
            line = line + 1
        end
    end
end

M.select_buffers = function()
    local bufnr = floats.center({ height = 0.25, width = 0.8, title = "Select buffers" })
    draw(bufnr)

    vim.keymap.set("n", "<enter>", function()
        local cursor_ln = vim.fn.getpos(".")[2]
        local _buf = line_to_bufnr[cursor_ln]
        if resource_state.active_bufs[_buf] == nil then
            resource_state.active_bufs[_buf] = true
        else
            resource_state.active_bufs[_buf] = nil
        end
        draw(bufnr)
    end, { buffer = bufnr })
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
    if resource_state.agent == "Copilot" then
        resource_state.agent = "Claude"
    else
        resource_state.agent = "Copilot"
    end
end

return M
