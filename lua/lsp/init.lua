local M = {}

local on_attach = function(bufnr)
    local buf_opts = { buffer = bufnr, silent = true }
    vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, buf_opts)

    vim.keymap.set("n", "gd", vim.lsp.buf.definition, buf_opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, buf_opts)
    vim.keymap.set("n", "gI", vim.lsp.buf.incoming_calls, buf_opts)
    vim.keymap.set("n", "gO", vim.lsp.buf.outgoing_calls, buf_opts)
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, buf_opts)
    vim.keymap.set("n", "<leader>ra", vim.lsp.buf.code_action, buf_opts)
    vim.keymap.set("n", "K", function()
        vim.lsp.buf.hover({ silent = true })
    end)

    vim.keymap.set("n", "<leader>ai", function()
        vim.lsp.inline_completion.enable(not vim.lsp.inline_completion.is_enabled())
        vim.cmd("redrawstatus")
    end, { desc = "enable inline completion" })

    vim.keymap.set("i", "<s-tab>", vim.lsp.inline_completion.get, { desc = "enable inline completion" })

    vim.keymap.set("n", "<leader>ih", function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 })
    end)

    vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave" }, {
        pattern = { "*.ts", "*.js", "*.go", "*.rs", "*.lua" },
        group = vim.api.nvim_create_augroup("user.lsp.codelens", { clear = true }),
        callback = function()
            vim.lsp.codelens.refresh({ bufnr = 0 })
        end,
    })

    vim.keymap.set("i", "<c-i>", "<c-x><c-o>", { desc = "trigger completion menu" })
end

require("lsp.diagnostics").setup()
require("mason").setup()
local servers = require("lsp.lsp_settings")

vim.api.nvim_create_autocmd({ "LspAttach" }, {
    group = vim.api.nvim_create_augroup("user.lsp.attach", { clear = true }),
    desc = "setup lsp specific keymaps",
    callback = function(ev)
        on_attach(ev.buf)
    end,
})

for server, _ in pairs(servers) do
    vim.lsp.config(server, {
        settings = servers[server],
        filetypes = (servers[server] or {}).filetypes,
    })

    vim.lsp.enable(server)
end

require("conform").setup({
    formatters_by_ft = {
        zig = { "zigfmt" },
        go = { "gofmt" },
        lua = { "stylua" },
        python = { "isort", "black" }, -- maybe can use ruff instead!
        rust = { "rustfmt", lsp_format = "fallback" },
        javascript = { "prettierd", "prettier" },
        typescript = { "prettierd", "prettier" },
        typescriptreact = { "prettierd", "prettier" },
        html = { "prettierd", "prettier" },
        astro = { "prettierd", "prettier" },
    },
})

vim.keymap.set({ "n", "v" }, "<leader>rr", function()
    require("conform").format({ async = true, lsp_fallback = "fallback", stop_after_first = false })
end)

return M
