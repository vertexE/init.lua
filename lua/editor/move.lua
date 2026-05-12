local M = {}

--- jumps the cursor to the position in winr,bufnr
--- @param winr integer
--- @param bufnr integer
--- @param line_nl 0-based index of where to jump to
M.jump_to = function(winr, bufnr, line_nl)
    vim.api.nvim_win_set_buf(winr, bufnr)
    vim.api.nvim_win_set_cursor(winr, { line_nl + 1, 0 })
end

return M
