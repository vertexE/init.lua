local M = {}

local on_attach = function(bufnr)
    local buf_opts = { buffer = bufnr, silent = true }
    vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, buf_opts)

    -- keymap("i", "<c-i>", vim.lsp.buf.signature_help, { noremap = true })
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, buf_opts)
    vim.keymap.set("n", "<leader>ra", vim.lsp.buf.code_action, buf_opts)
    vim.keymap.set("n", "K", function()
        vim.lsp.buf.hover({ silent = true })
    end)

    vim.keymap.set("n", "<leader>ai", function()
        vim.lsp.inline_completion.enable(not vim.lsp.inline_completion.is_enabled())
        vim.cmd("redrawstatus")
    end, { desc = "enable inline completion" })
    vim.keymap.set("i", "<tab>", vim.lsp.inline_completion.get, { desc = "enable inline completion" })

    vim.keymap.set("n", "<leader>ih", function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 })
    end)

    vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("user.lsp.codelens", { clear = true }),
        callback = function()
            vim.lsp.codelens.refresh({ bufnr = 0 })
        end,
    })

    vim.keymap.set("i", "<c-i>", function()
        -- <c-n> will grab completion by keywords if I don't see / know
        -- there will be nothing useful
        vim.lsp.completion.get()
    end)
end

require("lsp.diagnostics").setup()
require("mason").setup()
local servers = require("lsp.servers")

vim.api.nvim_create_autocmd({ "LspAttach" }, {
    group = vim.api.nvim_create_augroup("user.lsp.attach", { clear = true }),
    desc = "setup lsp specific keymaps",
    callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if client and client:supports_method("textDocument/completion") then
            vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
        end

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
    },
})

vim.keymap.set({ "n", "v" }, "<leader>rr", function()
    require("conform").format({ async = true, lsp_fallback = "fallback", stop_after_first = false })
end)

return M
