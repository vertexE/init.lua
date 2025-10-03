local M = {}

--- grab the start/end of the active selection, 1-based index
--- @return integer,integer
M.active_selection = function()
    local visual_line = vim.fn.getpos("v")[2]
    local cursor_line = vim.fn.getpos(".")[2]
    local start_line = math.min(visual_line, cursor_line)
    local end_line = math.max(visual_line, cursor_line)
    return start_line, end_line
end

--- grab the lines of the active selection
--- @return string[]
M.active_selection_lines = function()
    local visual_line = vim.fn.getpos("v")[2]
    local cursor_line = vim.fn.getpos(".")[2]
    local start_line = math.min(visual_line, cursor_line)
    local end_line = math.max(visual_line, cursor_line)
    return vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
end

return M
