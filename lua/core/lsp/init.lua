local M = {}

M.setup = function()
    require("core.lsp.diagnostics").set_config()
    require("core.lsp.attach").setup()
end

return M
