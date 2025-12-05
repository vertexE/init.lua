local M = {
    config = function()
        require("nvim-treesitter.configs").setup({
            ensure_installed = {
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
            },
            auto_install = false,
            highlight = { enable = true },
            indent = { enable = true },
            incremental_selection = {
                enable = true,
                keymaps = {
                    init_selection = "gnn",
                    node_incremental = "+",
                    scope_incremental = "grc",
                    node_decremental = "-",
                },
            },
            textobjects = {
                select = {
                    enable = true,

                    -- Automatically jump forward to textobj, similar to targets.vim
                    lookahead = true,

                    keymaps = {
                        -- You can use the capture groups defined in textobjects.scm
                        ["af"] = "@function.outer",
                        ["if"] = "@function.inner",
                        ["ac"] = "@class.outer",
                        -- You can optionally set descriptions to the mappings (used in the desc parameter of
                        -- nvim_buf_set_keymap) which plugins like which-key display
                        ["ic"] = { query = "@class.inner" },
                        -- You can also use captures from other query groups like `locals.scm`
                        -- ["as"] = { query = "@local.scope", query_group = "locals", desc = "Select language scope" },
                    },
                    -- You can choose the select mode (default is charwise 'v')
                    --
                    -- Can also be a function which gets passed a table with the keys
                    -- * query_string: eg '@function.inner'
                    -- * method: eg 'v' or 'o'
                    -- and should return the mode ('v', 'V', or '<c-v>') or a table
                    -- mapping query_strings to modes.
                    -- selection_modes = {
                    --     ["@parameter.outer"] = "v", -- charwise
                    --     ["@function.outer"] = "V", -- linewise
                    --     ["@class.outer"] = "<c-v>", -- blockwise
                    -- },
                },
            },
        })
    end,
}

return M
