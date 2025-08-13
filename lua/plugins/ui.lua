return {
    {
        "stevearc/aerial.nvim",
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "nvim-tree/nvim-web-devicons",
        },
        config = function()
            require("aerial").setup({
                -- optionally use on_attach to set keymaps when aerial has attached to a buffer
                on_attach = function(bufnr)
                    -- Jump forwards/backwards with '{' and '}'
                    vim.keymap.set("n", "[s", "<cmd>AerialPrev<CR>", { buffer = bufnr })
                    vim.keymap.set("n", "]s", "<cmd>AerialNext<CR>", { buffer = bufnr })
                end,
                open_automatic = false,
                layout = {
                    default_direction = "left",
                },
            })
            -- You probably also want to set a keymap to toggle aerial
            vim.keymap.set("n", "<leader>o", "<cmd>AerialToggle!<CR>")
        end,
    },
    {
        "NeogitOrg/neogit",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "folke/snacks.nvim",
        },
        config = function()
            local neogit = require("neogit")

            vim.keymap.set("n", "<leader>gg", function()
                neogit.open()
            end, { desc = "neogit: open status window" })
        end,
    },
    {
        "jbyuki/venn.nvim",
    },
    {
        "bassamsdata/namu.nvim",
        config = function()
            require("namu").setup({
                namu_symbols = {
                    enable = true,
                    options = { icon = "󱙝 ", window = { title_prefix = "󱙝 " } },
                },
                colorscheme = { enable = false },
                ui_select = { enable = false },
            })
            vim.keymap.set("n", "<leader>ft", ":Namu symbols<cr>", {
                desc = "Jump to LSP symbol",
                silent = true,
            })
        end,
    },
    {
        "lewis6991/gitsigns.nvim",
        lazy = true,
        event = "VeryLazy",
        enabled = false,
        config = function()
            local gitsigns = require("gitsigns")
            local buffer = require("core.editor.buffer")
            gitsigns.setup({
                signs_staged_enable = false,
            })

            vim.keymap.set("n", "]c", function()
                gitsigns.nav_hunk("next")
            end, { desc = "gitsigns: next hunk" })

            vim.keymap.set("n", "[c", function()
                gitsigns.nav_hunk("prev")
            end, { desc = "gitsigns: previous hunk" })

            vim.keymap.set("n", "<leader>gR", function()
                gitsigns.reset_buffer()
            end, { desc = "gitsigns: reset buffer" })

            vim.keymap.set("n", "<leader>gh", function()
                gitsigns.stage_buffer()
            end, { desc = "gitsigns: stage buffer" })

            vim.keymap.set({ "n", "v" }, "gh", function()
                gitsigns.stage_hunk()
            end, { desc = "gitsigns: stage hunk" })

            vim.keymap.set("n", "gH", function()
                local status = vim.api.nvim_get_mode()
                local is_visual_mode = status.mode == "v" or status.mode == "V" or status.mode == "^V"
                if is_visual_mode then
                    local sel_start, sel_end = buffer.active_selection()
                    gitsigns.reset_hunk({ sel_start, sel_end })
                else
                    gitsigns.reset_hunk()
                end
            end, { desc = "gitsigns: reset hunk" })

            -- vim.keymap.set("n", "<leader>gd", function()
            --     gitsigns.diffthis()
            -- end)

            vim.keymap.set("n", "<leader>gD", function()
                vim.ui.input({ prompt = "git revision" }, function(input)
                    if input == nil then
                        return
                    end
                    input = vim.trim(input)
                    if #input == 0 then
                        return
                    end
                    gitsigns.diffthis(input)
                end)
            end)
        end,
    },
    {
        "nvchad/minty",
        dependencies = {
            { "nvchad/volt", lazy = true, event = "VeryLazy" },
        },
        keys = {
            {
                "<leader>ch",
                function()
                    require("minty.huefy").open()
                end,
                mode = { "n" },
                desc = "color hues",
            },
            {
                "<leader>cs",
                function()
                    require("minty.shades").open()
                end,
                mode = { "n" },
                desc = "color shades",
            },
        },
    },
    {
        "folke/todo-comments.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        opts = {
            -- your configuration comes here
            -- or leave it empty to use the default settings
            -- refer to the configuration section below
        },
    },
    {
        "folke/noice.nvim",
        enabled = true,
        event = "VeryLazy",
        opts = {
            -- add any options here
        },
        dependencies = {
            -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
            "MunifTanjim/nui.nvim",
            -- OPTIONAL:
            -- `nvim-notify` is only needed, if you want to use the notification view.
            --   If not available, we use `mini` as the fallback
            -- "rcarriga/nvim-notify",
        },
        config = function()
            require("noice").setup({
                lsp = {
                    -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
                    override = {
                        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                        ["vim.lsp.util.stylize_markdown"] = true,
                        ["cmp.entry.get_documentation"] = true,
                    },
                    signature = {
                        enabled = true,
                    },
                },
                -- you can enable a preset for easier configuration
                presets = {
                    bottom_search = false, -- use a classic bottom cmdline for search
                    command_palette = true, -- position the cmdline and popupmenu together
                    long_message_to_split = true, -- long messages will be sent to a split
                    inc_rename = false, -- enables an input dialog for inc-rename.nvim
                    lsp_doc_border = true, -- add a border to hover docs and signature help
                },
            })
        end,
    },
}
