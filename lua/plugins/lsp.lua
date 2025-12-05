local lsp = require("lsp")

--- @type PackSpec
local M = {
    event = "BufEnter",
    requires = {
        "conform.nvim",
        "friendly-snippets",
        "blink.cmp",
        "lazydev.nvim",
        "mason.nvim",
        "mason-lspconfig.nvim",
        "tiny-inline-diagnostic.nvim",
    },
    config = function()
        require("mason").setup()
        lsp.setup()

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

        require("lazydev").setup({
            library = {
                -- See the configuration section for more details
                -- Load luvit types when the `vim.uv` word is found
                { path = "${3rd}/luv/library", words = { "vim%.uv" } },
            },
        })

        require("blink.cmp").setup({
            keymap = { preset = "default" },
            appearance = {
                nerd_font_variant = "mono",
            },
            completion = {
                documentation = { auto_show = true },
                menu = {
                    draw = {
                        -- treesitter = { "lsp" }, -- https://github.com/Saghen/blink.cmp/issues/2205
                        columns = {
                            { "kind_icon", gap = 2, "label", "label_description" },
                            { "source_name" },
                        },
                        components = {
                            source_name = {
                                text = function(ctx)
                                    local icons = {
                                        LSP = "",
                                        Snippets = "",
                                        Buffer = "",
                                        Path = "~",
                                        Copilot = "",
                                    }
                                    return icons[ctx.source_name] or ctx.source_name
                                end,
                                highlight = function(ctx)
                                    local hl_map = {
                                        LSP = "CmpItemKindKeyword",
                                        Snippets = "CmpItemKindSnippet",
                                        Buffer = "CmpItemKindText",
                                        Path = "CmpItemKindFile",
                                        Copilot = "CmpItemKindCopilot",
                                    }
                                    return { { group = hl_map[ctx.source_name] or "Identifier" } }
                                end,
                            },
                        },
                    },
                },
            },
            signature = { enabled = true, window = { show_documentation = false } },
            sources = {
                default = { "lsp", "path", "snippets", "buffer" },
            },
            fuzzy = { implementation = "prefer_rust_with_warning" },
        })
    end,
}

return M
