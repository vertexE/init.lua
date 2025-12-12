local M = {}

local custom_diagnostics = require("ui.diagnostics")

M.setup = function()
    custom_diagnostics.setup()

    vim.diagnostic.config({
        signs = false,
        virtual_text = false,
        virtual_lines = false,
        inlay_hint = {
            enable = true,
        },
        severity_sort = true,
        underline = false,
        float = {
            -- style = 'minimal',
            border = "rounded",
            source = true,
            header = "",
            prefix = "",
        },
    })
end

return M
