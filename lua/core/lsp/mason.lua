local M = {}

M.setup = function()
    require("mason").setup()
    local mason_lspconfig = require("mason-lspconfig")

    local global = require("core.lsp.global")
    local servers = require("core.lsp.servers")

    mason_lspconfig.setup()

    -- TODO: this might not always work?
    vim.lsp.config("*", {
        capabilities = global.capabilities,
        on_attach = global.on_attach,
    })

    vim.iter(mason_lspconfig.get_installed_servers()):each(function(server_name)
        vim.lsp.config(server_name, {
            settings = servers[server_name],
            filetypes = (servers[server_name] or {}).filetypes,
        })

        vim.lsp.enable(server_name)
    end)
end

return M
