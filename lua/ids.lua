local M = {}

M.uuidv4 = function()
    local result = vim.system({ "uuidgen" }):wait()
    return vim.trim(result.stdout)
end

return M
