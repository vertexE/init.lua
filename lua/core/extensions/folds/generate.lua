local M = {}

local FOLD_WINDOW = 4 -- show 4 lines above and below diagnostic

--- @param positions table<integer>
--- @return table<table<integer>>
M.folds_for_positions = function(positions)
    if #positions == 0 then
        return {}
    end

    local bufnr = vim.api.nvim_get_current_buf()
    table.sort(positions, function(a, b)
        return a < b
    end)

    local prev_pos = positions[1]
    local folds = { { 1, math.max(prev_pos - FOLD_WINDOW, 1) } }
    positions = { unpack(positions, 2) }
    for _, pos in pairs(positions) do
        if (prev_pos + FOLD_WINDOW) < (pos - FOLD_WINDOW) then -- no intersection, needs new fold
            table.insert(folds, { prev_pos + FOLD_WINDOW, pos - FOLD_WINDOW })
        end
        prev_pos = pos
    end

    -- special case for last position
    local last_line = vim.api.nvim_buf_line_count(bufnr)
    if (prev_pos + FOLD_WINDOW) < last_line then
        table.insert(folds, { (prev_pos + FOLD_WINDOW), last_line })
    end

    return folds
end

--- @param ranges table<table<integer>>
--- @return table<table<integer>>
M.folds_for_ranges = function(ranges)
    if #ranges == 0 then
        return {}
    end

    local bufnr = vim.api.nvim_get_current_buf()

    --- @param a table<integer>
    --- @param b table<integer>
    table.sort(ranges, function(a, b)
        return a[1] < b[1]
    end)

    local prev_range = ranges[1]
    local folds = { { 1, prev_range[1] } }
    ranges = { unpack(ranges, 2) }
    for _, range in pairs(ranges) do
        if prev_range[2] < range[1] then
            table.insert(folds, { prev_range[2], range[1] })
        end
        prev_range = range
    end

    local last_line = vim.api.nvim_buf_line_count(bufnr)
    if prev_range[2] < last_line then
        table.insert(folds, { prev_range[2], last_line })
    end

    return folds
end

return M
