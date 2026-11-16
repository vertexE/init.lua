local M = {}
local api = vim.api

function M.build(pair)
    local left, right = {}, {}
    local lo, ro = 0, 0
    pair.alignment = { [pair.left] = left, [pair.right] = right }
    pair.display_hunks = {}
    for i, hunk in ipairs(pair.hunks) do
        local height = math.max(hunk.lb - hunk.lt, hunk.rb - hunk.rt)
        local lpad = height - (hunk.lb - hunk.lt)
        local rpad = height - (hunk.rb - hunk.rt)
        pair.display_hunks[i] = {
            lt = hunk.lt + lo,
            lb = hunk.lb + lo + lpad,
            rt = hunk.rt + ro,
            rb = hunk.rb + ro + rpad,
            kind = hunk.kind,
        }
        if lpad > 0 then
            left[#left + 1] = { boundary = hunk.lb, start = hunk.lb + lo, size = lpad }
            lo = lo + lpad
        end
        if rpad > 0 then
            right[#right + 1] = { boundary = hunk.rb, start = hunk.rb + ro, size = rpad }
            ro = ro + rpad
        end
    end
end

function M.pad(buf, ns, pads)
    local count = api.nvim_buf_line_count(buf)
    for _, pad in ipairs(pads) do
        local above = pad.boundary < count
        local row = above and pad.boundary or count - 1
        local lines = {}
        for i = 1, pad.size do
            lines[i] = { { " " } }
        end
        api.nvim_buf_set_extmark(buf, ns, row, 0, {
            virt_lines = lines,
            virt_lines_above = above,
        })
    end
end

local function preceding_pad(pads, field, row)
    local first, last = 1, #pads
    while first <= last do
        local middle = math.floor((first + last) / 2)
        if pads[middle][field] <= row then
            first = middle + 1
        else
            last = middle - 1
        end
    end
    return pads[last]
end

-- Display rows are zero-based. Buffer lines are one-based.
function M.display_row(pads, line)
    local row = line - 1
    local pad = preceding_pad(pads, "boundary", row)
    return pad and row + pad.start - pad.boundary + pad.size or row
end

function M.buffer_line(pads, row)
    local pad = preceding_pad(pads, "start", row)
    if not pad then
        return row + 1, 0
    end
    if row < pad.start + pad.size then
        return pad.boundary + 1, pad.start + pad.size - row
    end
    return row - pad.start + pad.boundary - pad.size + 1, 0
end

function M.top(pads, view)
    return M.display_row(pads, view.topline) - view.topfill
end

function M.scroll(win, pads, top)
    return api.nvim_win_call(win, function()
        local view = vim.fn.winsaveview()
        local count = api.nvim_buf_line_count(0)
        local height = vim.fn.getwininfo(win)[1].height
        local line, fill = M.buffer_line(pads, top)
        local last = M.buffer_line(pads, top + height - 1)
        view.topline = math.min(line, count)
        -- Neovim keeps a real cursor line visible in each window.
        view.topfill = line <= count and math.min(fill, math.max(0, height - 1)) or 0
        view.lnum = math.min(count, math.max(view.topline, math.min(view.lnum, last)))
        vim.fn.winrestview(view)
        return M.top(pads, vim.fn.winsaveview())
    end)
end

return M
