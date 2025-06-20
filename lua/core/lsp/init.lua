local M = {}

M.setup = function()
    require("core.lsp.attach").setup()
    require("core.lsp.cmp").setup()
end

return M
