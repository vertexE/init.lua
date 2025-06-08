local M = {}
local keymap = vim.keymap.set

-- TODO: check if this line will do anything
-- local def_capabilities = vim.lsp.protocol.make_client_capabilities()
M.capabilities = require("cmp_nvim_lsp").default_capabilities()

-- client, buf id
local function lsp_keymaps(_, bufnr)
    local buf_opts = { buffer = bufnr, silent = true }

    -- errors
    keymap("n", "<leader>e", vim.diagnostic.open_float, buf_opts)

    -- inspection
    -- keymap("i", "<c-i>", vim.lsp.buf.signature_help, { noremap = true })
    -- actions
    keymap("n", "<leader>rn", vim.lsp.buf.rename, buf_opts)
    keymap("n", "<leader>ra", vim.lsp.buf.code_action, buf_opts)
end

local function set_diagnostic_config()
    local signs = require("core.ui.symbols").lsp_signs()
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
            source = "if_many",
            current_line = true,
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

local function setup_inlay_hints(_, bufnr)
    local function toggle_inlay_hints()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
    end

    vim.keymap.set("n", "<leader>ei", toggle_inlay_hints)
end

local function set_auto_commands(_, bufnr)
    -- vim.api.nvim_create_autocmd("CursorHold", {
    --     buffer = bufnr,
    --     callback = function()
    --         local opts = {
    --             focusable = false,
    --             close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
    --             border = 'rounded',
    --             source = 'always',
    --             prefix = ' ',
    --             -- scope = '...', -- line if default scope
    --         }
    --         vim.diagnostic.open_float(nil, opts)
    --     end
    -- })
end

M.on_attach = function(client, bufnr)
    set_auto_commands(client, bufnr)
    setup_inlay_hints(client, bufnr)
    set_diagnostic_config()
    lsp_keymaps(client, bufnr)
end

return M
