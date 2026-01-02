--- @type PackSpec
local M = {
    requires = { "nvim-treesitter" },
    config = function()
        require("nvim-treesitter").install({
            "lua",
            "rust",
            "python",
            "go",
            "c",
            "tsx",
            "html",
            "typescript",
            "javascript",
            "markdown",
            "markdown_inline",
            "vimdoc",
        })

        -- configuration
        require("nvim-treesitter-textobjects").setup({
            select = {
                -- Automatically jump forward to textobj, similar to targets.vim
                lookahead = true,
                -- You can choose the select mode (default is charwise 'v')
                --
                -- Can also be a function which gets passed a table with the keys
                -- * query_string: eg '@function.inner'
                -- * method: eg 'v' or 'o'
                -- and should return the mode ('v', 'V', or '<c-v>') or a table
                -- mapping query_strings to modes.
                selection_modes = {
                    ["@parameter.outer"] = "v", -- charwise
                    ["@function.outer"] = "V", -- linewise
                    ["@class.outer"] = "<c-v>", -- blockwise
                },
                -- If you set this to `true` (default is `false`) then any textobject is
                -- extended to include preceding or succeeding whitespace. Succeeding
                -- whitespace has priority in order to act similarly to eg the built-in
                -- `ap`.
                --
                -- Can also be a function which gets passed a table with the keys
                -- * query_string: eg '@function.inner'
                -- * selection_mode: eg 'v'
                -- and should return true of false
                include_surrounding_whitespace = false,
            },
        })

        vim.keymap.set({ "x", "o" }, "af", function()
            require("nvim-treesitter-textobjects.select").select_textobject("@function.outer", "textobjects")
        end)
        vim.keymap.set({ "x", "o" }, "if", function()
            require("nvim-treesitter-textobjects.select").select_textobject("@function.inner", "textobjects")
        end)
        vim.keymap.set({ "x", "o" }, "ac", function()
            require("nvim-treesitter-textobjects.select").select_textobject("@class.outer", "textobjects")
        end)
        vim.keymap.set({ "x", "o" }, "ic", function()
            require("nvim-treesitter-textobjects.select").select_textobject("@class.inner", "textobjects")
        end)

        vim.keymap.set({ "x", "o" }, "ap", function()
            require("nvim-treesitter-textobjects.select").select_textobject("@parameter.outer", "textobjects")
        end)
        vim.keymap.set({ "x", "o" }, "ip", function()
            require("nvim-treesitter-textobjects.select").select_textobject("@parameter.inner", "textobjects")
        end)

        vim.keymap.set("n", "<leader>sa", function()
            require("nvim-treesitter-textobjects.swap").swap_next("@parameter.inner")
        end, { desc = "ts: advance node" })
        vim.keymap.set("n", "<leader>sr", function()
            require("nvim-treesitter-textobjects.swap").swap_previous("@parameter.inner")
        end, { desc = "ts: retreat node" })
    end,
}

return M
