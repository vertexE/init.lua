return {
    {
        "stevearc/conform.nvim",
        event = { "BufWritePre" },
        cmd = { "ConformInfo" },
        keys = {
            {
                -- Customize or remove this keymap to your liking
                "<leader>rr",
                function()
                    require("conform").format({ async = true, lsp_fallback = "fallback", stop_after_first = false })
                end,
                mode = { "n", "v" },
                desc = "Format buffer",
            },
        },
        -- Everything in opts will be passed to setup()
        opts = {
            -- Define your formatters
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
            -- Set up format-on-save
            -- format_on_save = { timeout_ms = 500, lsp_fallback = true },
            -- Customize formatters
            -- formatters = {
            --     shfmt = {
            --         prepend_args = { "-i", "2" },
            --     },
            -- },
        },
        init = function()
            -- If you want the formatexpr, here is the place to set it
            vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
        end,
    },
}
