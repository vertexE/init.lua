local M = {}

local inline = require("ui.inline")

local ns = vim.api.nvim_create_namespace("user.editor.comments")
local comments_by_bufnr = {}
local next_order = 0
local current_lnum

local visible_lines = function(lines)
    local result = {}
    for _, line in ipairs(lines) do
        table.insert(result, line:gsub("[\r\n]", ""))
    end
    return result
end

local has_content = function(lines)
    for _, line in ipairs(lines) do
        if line:match("%S") then
            return true
        end
    end
    return false
end

local render = function(bufnr)
    for _, comment in ipairs(comments_by_bufnr[bufnr] or {}) do
        comment.lnum = current_lnum(bufnr, comment)
    end

    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

    local comments = comments_by_bufnr[bufnr] or {}
    for _, comment in ipairs(comments) do
        comment.mark_id = vim.api.nvim_buf_set_extmark(bufnr, ns, comment.lnum, 0, {
            id = comment.mark_id,
            virt_lines = vim.iter(comment.lines)
                :map(function(line)
                    return { { line, "Comment" } }
                end)
                :totable(),
            virt_lines_above = true,
        })
    end
end

current_lnum = function(bufnr, comment)
    local mark = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns, comment.mark_id, {})
    return mark and mark[1] or comment.lnum
end

local add_comment = function(bufnr, lnum, lines)
    lines = visible_lines(lines)
    if not has_content(lines) then
        return
    end

    next_order = next_order + 1
    comments_by_bufnr[bufnr] = comments_by_bufnr[bufnr] or {}
    table.insert(comments_by_bufnr[bufnr], {
        lnum = lnum,
        lines = lines,
        order = next_order,
    })

    render(bufnr)
end

M.add = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local lnum = vim.fn.getpos(".")[2] - 1

    inline.cursor({ title = "Comment" }, function(lines)
        add_comment(bufnr, lnum, lines)
    end)
end

M.clear = function(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    comments_by_bufnr[bufnr] = nil
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
end

M.copy_to_clipboard = function(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    local comments = vim.deepcopy(comments_by_bufnr[bufnr] or {})
    table.sort(comments, function(left, right)
        local left_lnum = current_lnum(bufnr, left)
        local right_lnum = current_lnum(bufnr, right)
        if left_lnum == right_lnum then
            return left.order < right.order
        end
        return left_lnum < right_lnum
    end)

    local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":.")
    if path == "" then
        path = "[No Name]"
    end

    local output = {}
    for _, comment in ipairs(comments) do
        table.insert(output, string.format("%s:%d", path, current_lnum(bufnr, comment) + 1))
        vim.list_extend(output, comment.lines)
        table.insert(output, "")
    end

    if #output > 0 then
        table.remove(output)
    end

    vim.fn.setreg("+", table.concat(output, "\n"))
    vim.notify(string.format("copied %d comments", #comments), vim.log.levels.INFO)
end

return M
