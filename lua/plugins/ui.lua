return {
    {
        -- GitSignsUpdate -- use in statusbar
        "josiahdenton/statusbar.nvim",
        -- dir = "/Users/jfdenton/work/statusbar.nvim",
        lazy = false,
        priority = 1000,
        dependencies = {
            {
                "lewis6991/gitsigns.nvim",
                lazy = true,
                event = "VeryLazy",
                config = function()
                    local gitsigns = require("gitsigns")
                    local buffer = require("core.editor.buffer")

                    gitsigns.setup({
                        signs_staged_enable = false,
                    })
                    vim.keymap.set("n", "<leader>gR", function()
                        gitsigns.reset_buffer()
                    end)
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

                    vim.keymap.set("n", "<leader>gd", function()
                        gitsigns.diffthis()
                    end)

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
        },
        config = function()
            require("statusbar").setup()
        end,
    },
    {
        "nvchad/minty",
        enabled = true,
        lazy = true,
        event = "VeryLazy",
        dependencies = {
            { "nvchad/volt", lazy = true },
        },
        config = function()
            vim.keymap.set("n", "<leader>ch", function()
                require("minty.huefy").open()
            end, { desc = "color hues" })

            vim.keymap.set("n", "<leader>cs", function()
                require("minty.shades").open()
            end, { desc = "color hues" })
        end,
    },
    {
        "stevearc/dressing.nvim",
        enabled = true,
        dependencies = {
            { "nvim-telescope/telescope.nvim" },
        },
        opts = {
            input = {
                relative = "win",
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
