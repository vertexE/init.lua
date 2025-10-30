local function in_comment(marker)
    local comment_tbl = {
        python = "#",
        lua = "--",
        c = "//",
        go = "//",
        rust = "//",
        javascript = "//",
        typescript = "//",
    }

    return function(bufnr)
        local comment = comment_tbl[vim.bo[bufnr].filetype]
        if comment == nil then
            return nil
        end

        return comment .. " ()" .. marker .. "()%f[%W]"
    end
end

return {
    config = function()
        vim.api.nvim_create_autocmd("FileType", {
            pattern = { "snacks_picker_input", "snacks_picker_list" },
            callback = function()
                vim.b.minicompletion_disable = true
            end,
            desc = "Disable mini.completion in snacks.nvim picker buffers",
        })

        require("mini.notify").setup()
        require("mini.icons").setup()
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
        mini_git.setup({})

        vim.keymap.set("n", "<leader>gc", function()
            vim.cmd("Git commit")
        end, { desc = "mini.git: commit" })

        local mini_diff = require("mini.diff")
        mini_diff.setup({
            view = {
                priority = 1,
            },
            mappings = { -- usage, gHgh resets textobject (hunk)
                apply = "gh",
                reset = "gH",
                textobject = "gh",
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
                bug = { pattern = in_comment("BUG"), group = "MiniIconsRed" },
                fixme = { pattern = in_comment("FIXME"), group = "MiniIconsRed" },
                hack = { pattern = in_comment("HACK"), group = "MiniIconsYellow" },
                warn = { pattern = in_comment("WARN"), group = "MiniIconsOrange" },
                todo = { pattern = in_comment("TODO"), group = "MiniIconsGreen" },
                perf = { pattern = in_comment("PERF"), group = "MiniIconsBlue" },
                note = { pattern = in_comment("NOTE"), group = "MiniIconsYellow" },
                info = { pattern = in_comment("INFO"), group = "MiniIconsYellow" },

                hex_color = hipatterns.gen_highlighter.hex_color(),
            },
        })

        require("mini.pick").setup()

        vim.keymap.set("n", "<leader>ff", function()
            require("mini.pick").builtin.files()
        end)

        vim.keymap.set("n", "<leader>fo", function()
            require("mini.extra").pickers.treesitter()
        end)

        vim.keymap.set("n", "<leader>fH", function()
            require("mini.extra").pickers.hl_groups()
        end)

        vim.keymap.set("n", "<leader>gb", function()
            require("mini.extra").pickers.git_branches()
        end)

        vim.keymap.set("n", "<leader>hk", function()
            require("mini.extra").pickers.keymaps()
        end)

        vim.keymap.set("n", "<localleader>ss", function()
            require("mini.extra").pickers.spellsuggest()
        end)

        vim.keymap.set("n", "<leader>fh", function()
            require("mini.pick").builtin.help()
        end)

        local buf_delete = function()
            vim.api.nvim_buf_delete(require("mini.pick").get_picker_matches().current.bufnr, {})
        end

        vim.keymap.set("n", "<leader>fb", function()
            require("mini.pick").builtin.buffers(
                nil,
                { mappings = { wipeout = { char = "<C-d>", func = buf_delete } } }
            )
        end)
    end,
}
