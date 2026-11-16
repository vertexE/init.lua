local M = {}
local api = vim.api
local graphics = require("vcs.diff.graphics")
local canvas_ns = api.nvim_create_namespace("vcs.diff.canvas")
local window_marks = {}

local styles = {
    add = { name = "DiffAdd", fallback = 0x345445 },
    delete = { name = "DiffDelete", fallback = 0x633e49 },
    change = { name = "DiffChange", fallback = 0x454963 },
}

local function palette()
    local colors = {}
    local number = api.nvim_get_hl(0, { name = "LineNr", link = false })
    local normal = api.nvim_get_hl(0, { name = "Normal", link = false })
    api.nvim_set_hl(0, "VcsRibbonNumber", { fg = number.fg or normal.fg })
    for kind, style in pairs(styles) do
        local highlight = api.nvim_get_hl(0, { name = style.name, link = false })
        local color = highlight.bg or style.fallback
        colors[kind] = color
        api.nvim_set_hl(0, "VcsRibbonFill" .. kind, { bg = color })
        api.nvim_set_hl(0, "VcsRibbonNumber" .. kind, { fg = normal.fg, bg = color })
        api.nvim_set_hl(0, "VcsRibbonOrigin" .. kind, { sp = color, underline = true })
        api.nvim_set_hl(0, "VcsRibbonPoint" .. kind, { fg = number.fg, sp = color, underline = true })
        api.nvim_set_hl(0, "VcsRibbon" .. kind, { fg = color, nocombine = true })
    end
    return colors
end

local function curve(x)
    -- Cubic Bézier with horizontal tangents and x controls at 30% and 70%.
    local t = x
    for _ = 1, 3 do
        t = t - (((-0.2 * t + 0.3) * t + 0.9) * t - x) / ((-0.6 * t + 0.6) * t + 0.9)
    end
    return t * t * (3 - 2 * t)
end

function M.hunks(pair, left, right)
    pair.hunks = {}
    for _, hunk in ipairs(vim.diff(left, right, { result_type = "indices", algorithm = "histogram" })) do
        local a, na, b, nb = unpack(hunk)
        local kind = na == 0 and "add" or nb == 0 and "delete" or "change"
        local l = na == 0 and a or a - 1
        local r = nb == 0 and b or b - 1
        pair.hunks[#pair.hunks + 1] = { lt = l, lb = l + na, rt = r, rb = r + nb, kind = kind }
    end
    pair.viewport = nil
end

function M.highlight(contexts)
    local spans = {}
    for _, pair in ipairs(contexts) do
        spans[pair.left] = {}
        spans[pair.right] = {}
    end
    for _, pair in ipairs(contexts) do
        for _, hunk in ipairs(pair.hunks) do
            spans[pair.left][#spans[pair.left] + 1] = { hunk.lt, hunk.lb, hunk.kind }
            spans[pair.right][#spans[pair.right] + 1] = { hunk.rt, hunk.rb, hunk.kind }
        end
    end
    for win, ranges in pairs(spans) do
        local buf = api.nvim_win_get_buf(win)
        local marks = window_marks[win]
        if not marks then
            local ns = api.nvim_create_namespace("")
            api.nvim__ns_set(ns, { wins = { win } })
            marks = { buf = buf, ns = ns }
            window_marks[win] = marks
        end
        api.nvim_buf_clear_namespace(buf, marks.ns, 0, -1)
        local count = api.nvim_buf_line_count(buf)
        for _, range in ipairs(ranges) do
            local first, last, kind = unpack(range)
            if first == last and first > 0 and first <= count then
                api.nvim_buf_set_extmark(buf, marks.ns, first - 1, 0, {
                    line_hl_group = "VcsRibbonOrigin" .. kind,
                    priority = 91,
                })
            end
            for row = first, math.min(last, count) - 1 do
                api.nvim_buf_set_extmark(buf, marks.ns, row, 0, {
                    line_hl_group = "VcsRibbonFill" .. kind,
                    priority = 90,
                })
            end
        end
    end
end

local function glyphs(ribbons, cols, rows)
    local cells = {}
    for row = 1, rows do
        cells[row] = {}
    end
    for col = 1, cols do
        local t = curve((col - 0.5) / cols)
        for _, ribbon in ipairs(ribbons) do
            local top = ribbon.lt + (ribbon.rt - ribbon.lt) * t
            local bottom = ribbon.lb + (ribbon.rb - ribbon.lb) * t
            local first = math.floor(top * 2)
            local last = math.max(first, math.ceil(bottom * 2) - 1)
            for half = math.max(0, first), math.min(rows * 2 - 1, last) do
                local row = math.floor(half / 2) + 1
                local cell = cells[row][col]
                local shape = half % 2 == 0 and "▀" or "▄"
                if cell and cell.kind == ribbon.kind and cell.shape ~= shape then
                    shape = "█"
                end
                cells[row][col] = { kind = ribbon.kind, shape = shape }
            end
        end
    end
    local lines, marks = {}, {}
    for row, cells_on_row in ipairs(cells) do
        local parts, byte = {}, 0
        for col = 1, cols do
            local cell = cells_on_row[col]
            local part = cell and cell.shape or " "
            parts[col] = part
            if cell then
                marks[#marks + 1] = { row - 1, byte, byte + #part, "VcsRibbon" .. cell.kind }
            end
            byte = byte + #part
        end
        lines[row] = table.concat(parts)
    end
    return lines, marks
end

local function viewport_offset(info, gutter)
    return info.topline - 1 - (info.winrow + info.winbar - gutter.winrow)
end

local function numbers(info, buf, offset, rows, width, ribbons, side)
    local cells, highlights = {}, {}
    local count = api.nvim_buf_line_count(buf)
    for _, ribbon in ipairs(ribbons) do
        local top, bottom = ribbon[side .. "t"], ribbon[side .. "b"]
        if top == bottom and top >= 1 and top <= rows then
            highlights[top] = "VcsRibbonPoint" .. ribbon.kind
        end
        for row = math.max(1, top + 1), math.min(rows, bottom) do
            highlights[row] = "VcsRibbonNumber" .. ribbon.kind
        end
    end
    for row = 1, rows do
        local line = row + offset
        local label = line >= info.topline and line <= count and tostring(line) or ""
        label = #label < width and label or ""
        local padding = string.rep(" ", math.max(0, width - #label - 1))
        cells[row] = width == 0 and "" or (side == "l" and padding .. label .. " " or " " .. label .. padding)
    end
    return cells, highlights
end

function M.paint(pair)
    local left = vim.fn.getwininfo(pair.left)[1]
    local right = vim.fn.getwininfo(pair.right)[1]
    local gutter = vim.fn.getwininfo(pair.gutter)[1]
    local rows, cols = gutter.height, gutter.width + 2
    local margin = math.min(pair.number_width, math.floor((cols - 1) / 2))
    local core = cols - 2 * margin
    local l, r = viewport_offset(left, gutter), viewport_offset(right, gutter)
    local images = graphics.enabled()
    local viewport = { l, r, rows, cols, gutter.winrow, gutter.wincol, images and true or false }
    if vim.deep_equal(pair.viewport, viewport) then
        return
    end
    pair.viewport = viewport
    local config = {
        relative = "editor",
        row = gutter.winrow - 1,
        col = gutter.wincol - 2,
        width = cols,
        height = rows,
        style = "minimal",
        border = "none",
        focusable = false,
        mouse = false,
        zindex = 10,
    }
    if pair.float and api.nvim_win_is_valid(pair.float) then
        api.nvim_win_set_config(pair.float, config)
    else
        config.noautocmd = true
        pair.float = api.nvim_open_win(pair.canvas, false, config)
        vim.wo[pair.float].wrap = false
        vim.wo[pair.float].winhighlight = "NormalFloat:Normal,Normal:Normal"
    end

    local ribbons = {}
    for _, hunk in ipairs(pair.hunks) do
        local lt, lb, rt, rb = hunk.lt - l, hunk.lb - l, hunk.rt - r, hunk.rb - r
        if (lb > 0 or rb > 0) and (lt < rows or rt < rows) then
            ribbons[#ribbons + 1] = { lt = lt, lb = lb, rt = rt, rb = rb, kind = hunk.kind }
        end
    end
    local colors = palette()
    local hl, lines, marks
    if #ribbons > 0 and images then
        hl, lines = graphics.paint(pair.image, ribbons, core, rows, colors, curve)
        if hl then
            pair.placeholders = lines or pair.placeholders
            lines = pair.placeholders
        end
    end
    if not hl then
        graphics.destroy(pair.image)
        lines, marks = glyphs(ribbons, core, rows)
    end

    local left_numbers, left_hl = numbers(left, left.bufnr, l, rows, margin, ribbons, "l")
    local right_numbers, right_hl = numbers(right, right.bufnr, r, rows, margin, ribbons, "r")
    local canvas = {}
    for row, line in ipairs(lines) do
        canvas[row] = left_numbers[row] .. line .. right_numbers[row]
    end
    api.nvim_buf_set_lines(pair.canvas, 0, -1, false, canvas)
    api.nvim_buf_clear_namespace(pair.canvas, canvas_ns, 0, -1)
    local function mark(row, first, last, group)
        if first < last then
            api.nvim_buf_set_extmark(pair.canvas, canvas_ns, row, first, {
                end_col = last,
                hl_group = group,
                hl_mode = "replace",
            })
        end
    end
    for row, line in ipairs(lines) do
        local first = #left_numbers[row]
        mark(row - 1, 0, first, left_hl[row] or "VcsRibbonNumber")
        mark(row - 1, first + #line, #canvas[row], right_hl[row] or "VcsRibbonNumber")
        if hl then
            mark(row - 1, first, first + #line, hl)
        end
    end
    for _, cell in ipairs(marks or {}) do
        local first = #left_numbers[cell[1] + 1]
        mark(cell[1], first + cell[2], first + cell[3], cell[4])
    end
end

function M.invalidate(pair)
    pair.viewport = nil
    graphics.destroy(pair.image)
end

function M.close(pair)
    for _, win in ipairs({ pair.left, pair.right }) do
        local marks = window_marks[win]
        if marks and api.nvim_buf_is_valid(marks.buf) then
            api.nvim_buf_clear_namespace(marks.buf, marks.ns, 0, -1)
        end
        window_marks[win] = nil
    end
    graphics.destroy(pair.image)
end

return M
