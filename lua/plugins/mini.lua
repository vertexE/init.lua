return {
    config = function()
        require("mini.completion").setup()
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

        local mini_files = require("mini.files")
        mini_files.setup({
            windows = {
                width_focus = 80,
            },
        })

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
                fixme = { pattern = "FIXME", group = "MiniHipatternsFixme" },
                hack = { pattern = "HACK", group = "MiniHipatternsHack" },
                todo = { pattern = "TODO", group = "MiniHipatternsTodo" },
                note = { pattern = "NOTE", group = "MiniHipatternsNote" },

                hex_color = hipatterns.gen_highlighter.hex_color(),
            },
        })
    end,
}
