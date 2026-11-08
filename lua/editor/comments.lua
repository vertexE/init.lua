local M = {
    context_lines = 3,
}

local textarea = require("ui.textarea")

local ns = vim.api.nvim_create_namespace("user.editor.comments")
local draft_ns = vim.api.nvim_create_namespace("user.editor.comments.draft")
local preview_ns = vim.api.nvim_create_namespace("user.editor.comments.preview")
local comments_by_bufnr = {}
local virtual_lines_overflow = vim.fn.has("nvim-0.13") == 1 and "wrap" or nil

local function virtual_lines(lines)
    return vim.tbl_map(function(line)
        return { { line, "Comment" } }
    end, lines)
end

local function get_range(bufnr, namespace, id)
    local mark = vim.api.nvim_buf_get_extmark_by_id(bufnr, namespace, id, { details = true })
    if #mark == 0 then
        return
    end

    local first, last = mark[1], mark[3].end_row - 1
    if vim.api.nvim_buf_is_loaded(bufnr) then
        local last_line = vim.api.nvim_buf_line_count(bufnr) - 1
        first, last = math.min(first, last_line), math.min(last, last_line)
    end
    return first, math.max(first, last)
end

local function fill_preview(bufnr, source, first, last)
    -- Parse the full source so captures and injections can span the preview boundaries.
    vim.treesitter.stop(bufnr)
    vim.bo[bufnr].syntax = ""
    vim.bo[bufnr].tabstop = vim.bo[source].tabstop
    vim.bo[bufnr].vartabstop = vim.bo[source].vartabstop
    vim.bo[bufnr].modifiable = true
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.api.nvim_buf_get_lines(source, 0, -1, false))
    vim.bo[bufnr].modifiable = false

    local ft = vim.bo[source].filetype
    if ft ~= "" and not pcall(vim.treesitter.start, bufnr, vim.treesitter.language.get_lang(ft)) then
        vim.bo[bufnr].syntax = ft
    end

    vim.api.nvim_buf_clear_namespace(bufnr, preview_ns, 0, -1)
    for row = first, last do
        vim.api.nvim_buf_set_extmark(bufnr, preview_ns, row, 0, { line_hl_group = "DiffAdd" })
    end
end

local function show_context(winr, top)
    local topline = top + 1
    vim.wo[winr].foldenable = false
    vim.wo[winr].scrolloff = 0
    vim.wo[winr].wrap = false
    vim.api.nvim_win_call(winr, function()
        vim.fn.winrestview({ lnum = topline, col = 0, topline = topline, leftcol = 0 })
    end)
end

M.add = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local first = vim.api.nvim_win_get_cursor(0)[1] - 1
    local last = first
    local mode = vim.fn.mode()
    if mode == "v" or mode == "V" or mode == "\22" then
        local anchor = vim.fn.line("v") - 1
        first, last = math.min(first, anchor), math.max(first, anchor)
        vim.cmd.normal({ "\27", bang = true })
    end

    local screen_height = vim.o.lines - math.max(1, vim.o.cmdheight)
    local input_height = 4
    local borders = 4
    if screen_height <= input_height + borders or vim.o.columns < 3 then
        vim.notify("Editor too small for comment composer", vim.log.levels.WARN)
        return
    end

    local max_height = screen_height - input_height - borders
    local top = math.max(0, first - math.min(M.context_lines, max_height - 1))
    local bottom = math.min(vim.api.nvim_buf_line_count(bufnr) - 1, last + M.context_lines)
    local height = math.min(bottom - top + 1, max_height)
    local width = math.min(vim.o.columns - 2, math.floor(vim.o.columns * 0.75))
    local row = math.floor((screen_height - height - input_height - borders) / 2)
    local col = math.floor((vim.o.columns - width - 2) / 2)

    local code_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[code_buf].bufhidden = "wipe"
    fill_preview(code_buf, bufnr, first, last)
    local code_win = vim.api.nvim_open_win(code_buf, false, {
        relative = "editor",
        style = "minimal",
        border = "rounded",
        title = " Code ",
        row = row,
        col = col,
        height = height,
        width = width,
    })
    show_context(code_win, top)

    local draft = vim.api.nvim_buf_set_extmark(bufnr, draft_ns, first, 0, { end_row = last + 1, end_col = 0 })
    local _, input_win = textarea.open({
        prompt = " Comment ",
        row = row + height + 2,
        col = col,
        height = input_height,
        width = width,
    }, function(lines)
        if not vim.api.nvim_buf_is_loaded(bufnr) then
            return
        end
        local start_row, end_row = get_range(bufnr, draft_ns, draft)
        if not start_row then
            return
        end

        local id = vim.api.nvim_buf_set_extmark(bufnr, ns, start_row, 0, {
            end_row = end_row + 1,
            end_col = 0,
            virt_lines = virtual_lines(lines),
            virt_lines_overflow = virtual_lines_overflow,
            -- Virtual lines above the first buffer line are outside the viewport.
            virt_lines_above = start_row > 0,
        })
        comments_by_bufnr[bufnr] = comments_by_bufnr[bufnr] or {}
        table.insert(comments_by_bufnr[bufnr], { id = id, lines = lines })
    end)

    vim.api.nvim_create_autocmd("WinClosed", {
        pattern = tostring(input_win),
        once = true,
        callback = function()
            if vim.api.nvim_win_is_valid(code_win) then
                vim.api.nvim_win_close(code_win, true)
            end
            -- Textarea closes its window before invoking the submit callback.
            vim.schedule(function()
                if vim.api.nvim_buf_is_valid(bufnr) then
                    vim.api.nvim_buf_del_extmark(bufnr, draft_ns, draft)
                end
            end)
        end,
    })
end

M.clear = function()
    for bufnr in pairs(comments_by_bufnr) do
        if vim.api.nvim_buf_is_valid(bufnr) then
            vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
        end
    end
    comments_by_bufnr = {}
end

local function comment_items()
    local items = {}

    for bufnr, comments in pairs(comments_by_bufnr) do
        if vim.api.nvim_buf_is_valid(bufnr) then
            local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":.")
            if path == "" then
                path = "[No Name]"
            end

            for _, comment in ipairs(comments) do
                local first = get_range(bufnr, ns, comment.id)
                if first then
                    local location = string.format("%s:%d", path, first + 1)
                    table.insert(items, {
                        buf = bufnr,
                        pos = { first + 1, 0 },
                        path = path,
                        location = location,
                        text = location .. " " .. table.concat(comment.lines, " "),
                        comment = comment,
                    })
                end
            end
        end
    end

    table.sort(items, function(left, right)
        if left.path ~= right.path then
            return left.path < right.path
        end
        if left.pos[1] ~= right.pos[1] then
            return left.pos[1] < right.pos[1]
        end
        return left.comment.id < right.comment.id
    end)
    return items
end

M.copy_to_clipboard = function()
    local items = comment_items()
    local output = {}
    for _, item in ipairs(items) do
        table.insert(output, item.location)
        vim.list_extend(output, item.comment.lines)
        table.insert(output, "")
    end

    if #output > 0 then
        table.remove(output)
    end

    vim.fn.setreg("+", table.concat(output, "\n"))
    vim.notify(string.format("copied %d comments", #items), vim.log.levels.INFO)
end

M.pick = function()
    require("snacks").picker.pick("code_comments", {
        title = "Code Comments",
        items = comment_items(),
        format = function(item)
            return { { item.location, "Comment" }, { "  " .. table.concat(item.comment.lines, " ") } }
        end,
        preview = function(ctx)
            local item = ctx.item
            if not vim.api.nvim_buf_is_valid(item.buf) then
                ctx.preview:reset()
                return
            end
            vim.fn.bufload(item.buf)
            local first, last = get_range(item.buf, ns, item.comment.id)
            if not first then
                ctx.preview:reset()
                return
            end

            fill_preview(ctx.buf, item.buf, first, last)
            vim.api.nvim_buf_set_extmark(ctx.buf, preview_ns, first, 0, {
                virt_lines = virtual_lines(item.comment.lines),
                virt_lines_overflow = virtual_lines_overflow,
            })
            ctx.preview:set_title(item.location)
            local context = math.min(M.context_lines, math.max(0, vim.api.nvim_win_get_height(ctx.win) - 2))
            show_context(ctx.win, math.max(0, first - context))
        end,
    })
end

return M
