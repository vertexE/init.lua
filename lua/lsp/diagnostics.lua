local M = {}

M.setup = function()
    local signs = require("symbols").lsp_signs()
    for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
    end

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
        virtual_text = {
            spacing = 4,
            severity = {}, -- vim.diagnostic.severity.ERROR, vim.diagnostic.severity.WARN -- temporarily turn of virtual text
            source = "if_many",
            -- current_line = true,
            --- @param diagnostic vim.Diagnostic
            format = function(diagnostic)
                local icon = ""
                if diagnostic.code == "unused-local" or diagnostic.code == 6133 then
                    icon = signs.HINT
                end
                if diagnostic.severity == vim.diagnostic.severity.ERROR then
                    icon = signs.Error
                end
                if diagnostic.severity == vim.diagnostic.severity.WARN then
                    icon = signs.Warn
                end
                if diagnostic.severity == vim.diagnostic.severity.INFO then
                    icon = signs.Info
                end
                if diagnostic.severity == vim.diagnostic.severity.HINT then
                    icon = signs.Hint
                end
                local lines = vim.split(diagnostic.message, "\n")
                local message = lines[1]
                if #lines > 1 then
                    message = message .. "..."
                end
                return string.format("%s %s", icon, message)
            end,
            prefix = "",
        },
        inlay_hint = {
            enable = true,
        },
        severity_sort = true,
        underline = true,
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
