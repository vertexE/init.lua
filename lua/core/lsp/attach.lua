local M = {}

local keymap = vim.keymap.set

local function lsp_keymaps(bufnr)
    local buf_opts = { buffer = bufnr, silent = true }

    -- errors
    keymap("n", "<leader>e", vim.diagnostic.open_float, buf_opts)

    -- inspection
    -- keymap("i", "<c-i>", vim.lsp.buf.signature_help, { noremap = true })
    -- actions
    keymap("n", "<leader>rn", vim.lsp.buf.rename, buf_opts)
    keymap("n", "<leader>ra", vim.lsp.buf.code_action, buf_opts)
    keymap("n", "K", function()
        vim.lsp.buf.hover({ silent = true })
    end)
end

local function inlay_hints(bufnr)
    local function toggle_inlay_hints()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
    end

    vim.keymap.set("n", "<leader>ih", toggle_inlay_hints)
end

local function auto_commands(bufnr)
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

local on_attach = function(bufnr)
    auto_commands(bufnr)
    inlay_hints(bufnr)
    lsp_keymaps(bufnr)
end

M.setup = function()
    require("mason").setup()
    local mason_lspconfig = require("mason-lspconfig")

    local servers = require("core.lsp.servers")

    vim.api.nvim_create_autocmd({ "LspAttach" }, {
        group = vim.api.nvim_create_augroup("user/lsp/attach", { clear = true }),
        desc = "setup lsp specific keymaps",
        callback = function(args)
            on_attach(args.buf)
        end,
    })

    mason_lspconfig.setup()
    vim.iter(mason_lspconfig.get_installed_servers()):each(function(server_name)
        vim.lsp.config(server_name, {
            settings = servers[server_name],
            filetypes = (servers[server_name] or {}).filetypes,
        })

        vim.lsp.enable(server_name)
    end)
end

return M
