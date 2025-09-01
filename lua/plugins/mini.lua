return {
    {
        "nvim-mini/mini.nvim",
        version = false,
        enabled = true,
        event = "VeryLazy",
        config = function()
            require("mini.icons").setup()
            require("mini.notify").setup()
            require("mini.cursorword").setup({ delay = 500 })
            require("mini.ai").setup()
            require("mini.pairs").setup()
            require("mini.indentscope").setup({
                -- symbol = "󰇙",
                options = { try_as_border = true },
            })
            -- disable indentscope for specific files...
            vim.api.nvim_create_autocmd("FileType", {
                pattern = {
                    "help",
                    "alpha",
                    "dashboard",
                    "neo-tree",
                    "Trouble",
                    "lazy",
                    "mason",
                    "notify",
                    "toggleterm",
                    "lazyterm",
                },
                callback = function()
                    vim.b.miniindentscope_disable = true
                end,
            })

            local mini_git = require("mini.git")
            mini_git.setup()

            vim.keymap.set("n", "<leader>gc", function()
                vim.cmd("Git commit")
            end, { desc = "mini.git: commit" })

            local mini_diff = require("mini.diff")
            mini_diff.setup({
                view = {
                    priority = 1,
                },
                mappings = {
                    apply = "",
                    reset = "",
                },
            })

            vim.keymap.set("n", "<leader>gd", function()
                mini_diff.toggle_overlay(0)
            end)

            -- vim.keymap.set({ "n", "v" }, "<leader>gi", function()
            --     mini_git.show_at_cursor()
            -- end)

            -- vim.keymap.set({ "n" }, "<leader>gb", function()
            --     vim.cmd("Git blame -- %")
            -- end, { desc = "git blame file" })

            -- local buffer = require("core.editor.buffer")
            -- vim.keymap.set({ "v", "x" }, "<leader>gb", function()
            --     local _start, _end = buffer.active_selection()
            --     vim.cmd(string.format("Git blame -L %d,%d -- %%", _start, _end))
            -- end, { desc = "git blame selection" })

            local mini_files = require("mini.files")
            mini_files.setup()

            local mini_open = function()
                mini_files.open(vim.api.nvim_buf_get_name(0))
            end
            vim.keymap.set("n", "<leader>N", mini_open)

            require("mini.bracketed").setup({
                buffer = { suffix = "b", options = {} },
                comment = { suffix = "", options = {} },
                conflict = { suffix = "x", options = {} },
                diagnostic = { suffix = "d", options = {} },
                file = { suffix = "f", options = {} },
                indent = { suffix = "i", options = {} },
                jump = { suffix = "j", options = {} },
                location = { suffix = "l", options = {} },
                oldfile = { suffix = "o", options = {} },
                quickfix = { suffix = "q", options = {} },
                treesitter = { suffix = "", options = {} },
                undo = { suffix = "", options = {} },
                window = { suffix = "w", options = {} },
                yank = { suffix = "y", options = {} },
            })

            local hipatterns = require("mini.hipatterns")
            hipatterns.setup({
                highlighters = {
                    -- Highlight hex color strings (`#rrggbb`) using that color
                    hex_color = hipatterns.gen_highlighter.hex_color(),
                },
            })

            local check_macro_recording = function()
                if vim.fn.reg_recording() ~= "" then
                    return "recording @" .. vim.fn.reg_recording()
                else
                    return ""
                end
            end

            -- local MiniStatusline = require("mini.statusline")
            -- MiniStatusline.setup({
            --     use_icons = vim.g.have_nerd_font,
            --     content = {
            --         active = function()
            --             local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = 120 })
            --             local git = MiniStatusline.section_git({ trunc_width = 40 })
            --             local diff = MiniStatusline.section_diff({ trunc_width = 75 })
            --             local diagnostics = MiniStatusline.section_diagnostics({ trunc_width = 75 })
            --             local lsp = MiniStatusline.section_lsp({ trunc_width = 75 })
            --             local filename = MiniStatusline.section_filename({ trunc_width = 140 })
            --             local fileinfo = MiniStatusline.section_fileinfo({ trunc_width = 120 })
            --             local location = MiniStatusline.section_location({ trunc_width = 200 })
            --             local search = MiniStatusline.section_searchcount({ trunc_width = 75 })
            --             local macro = check_macro_recording()
            --
            --             return MiniStatusline.combine_groups({
            --                 { hl = mode_hl, strings = { mode } },
            --                 { hl = "MiniStatuslineDevinfo", strings = { git, diff, diagnostics, lsp } },
            --                 "%<", -- Mark general truncate point
            --                 { hl = "MiniStatuslineFilename", strings = { filename } },
            --                 "%=", -- End left alignment
            --                 { hl = "MiniStatuslineFilename", strings = { macro } }, -- TODO: add better hl
            --                 { hl = "MiniStatuslineFileinfo", strings = { fileinfo } },
            --                 { hl = mode_hl, strings = { search, location } },
            --             })
            --         end,
            --     },
            -- })
        end,
    },
}
