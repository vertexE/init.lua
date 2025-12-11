local M = {}

local custom_diagnostics = require("ui.diagnostics")

M.setup = function()
    local signs = require("symbols").lsp_signs()
    for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
    end

    custom_diagnostics.setup()

    vim.diagnostic.config({
        signs = {
            enable = true,
            text = {
                ["ERROR"] = signs.Error,
                ["WARN"] = signs.Warn,
                ["HINT"] = signs.Hint,
                ["INFO"] = signs.Info,
            },
        },
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
