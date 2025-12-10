local M = {}

local on_attach = function(bufnr)
    local buf_opts = { buffer = bufnr, silent = true }
    vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, buf_opts)

    vim.keymap.set("n", "gI", vim.lsp.buf.incoming_calls, buf_opts)
    vim.keymap.set("n", "gO", vim.lsp.buf.outgoing_calls, buf_opts)
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, buf_opts)
    vim.keymap.set("n", "<leader>ra", vim.lsp.buf.code_action, buf_opts)
    vim.keymap.set("n", "K", function()
        vim.lsp.buf.hover({ silent = true })
    end)

    -- vim.keymap.set("n", "<leader>ai", function()
    --     vim.lsp.inline_completion.enable(not vim.lsp.inline_completion.is_enabled())
    --     vim.cmd("redrawstatus")
    -- end, { desc = "enable inline completion" })

    vim.keymap.set("i", "<s-tab>", vim.lsp.inline_completion.get, { desc = "enable inline completion" })

    vim.keymap.set("n", "<leader>ih", function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 })
    end)

    vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave" }, {
        pattern = { "*.ts", "*.js", "*.go", "*.rs", "*.lua" },
        group = vim.api.nvim_create_augroup("user.lsp.codelens", { clear = true }),
        callback = function(ev)
            -- vim.lsp.codelens.refresh({})
            -- local buf_lens = vim.lsp.codelens.get(ev.buf)
            -- vim.print(buf_lens)
            -- vim.lsp.buf.document_symbol({on_list = function (symbols)
            --     vim.print(symbols)
            -- end})
            -- local ns = vim.api.nvim_create_namespace("user.codelens.ui")
            -- for _, lens in ipairs(buf_lens) do
            -- end
        end,
    })




    vim.keymap.set("i", "<c-i>", "<c-x><c-o>", { desc = "trigger completion menu" })
end

M.setup = function()
    require("lsp.diagnostics").setup()
    require("ui.codelens").setup()
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
end

return M
