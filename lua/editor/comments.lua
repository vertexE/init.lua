local M = {}

local inline = require("ui.inline")

local ns = vim.api.nvim_create_namespace("user.editor.comments")
local comments_by_bufnr = {}
local next_order = 0

local current_lnum = function(bufnr, comment)
    if not comment.mark_id then
        return comment.lnum
    end

    local mark = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns, comment.mark_id, {})
    return mark and mark[1] or comment.lnum
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

local add_comment = function(bufnr, lnum, lines)
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

M.clear = function()
    for bufnr, _ in pairs(comments_by_bufnr) do
        vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    end
    comments_by_bufnr = {}
end

M.copy_to_clipboard = function()
    local items = {}

    for bufnr, comments in pairs(comments_by_bufnr) do
        local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":.")
        if path == "" then
            path = "[No Name]"
        end

        for _, comment in ipairs(comments) do
            table.insert(items, {
                bufnr = bufnr,
                comment = comment,
                lnum = current_lnum(bufnr, comment),
                path = path,
            })
        end
    end

    table.sort(items, function(left, right)
        if left.path ~= right.path then
            return left.path < right.path
        end
        if left.lnum ~= right.lnum then
            return left.lnum < right.lnum
        end
        return left.comment.order < right.comment.order
    end)

    local output = {}
    for _, item in ipairs(items) do
        table.insert(output, string.format("%s:%d", item.path, item.lnum + 1))
        vim.list_extend(output, item.comment.lines)
        table.insert(output, "")
    end

    if #output > 0 then
        table.remove(output)
    end

    vim.fn.setreg("+", table.concat(output, "\n"))
    vim.notify(string.format("copied %d comments", #items), vim.log.levels.INFO)
end

return M
