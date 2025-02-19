return {
    -- vim.cmd("highlight CustomCmpPicker guibg=#b4ebbc guifg=#212031 gui=bold")
    {
        "folke/tokyonight.nvim",
        lazy = false,
        enabled = true,
        priority = 1000,
        config = function()
            require("tokyonight").setup({
                on_highlights = function(hl, c)
                    hl.MiniCursorword = { underline = true }
                    hl.MiniCursorwordCurrent = { underline = true }
                    hl.HighlightYank = { bg = c.magenta }
                    hl.AIActionsHeader = { fg = c.green, bold = true }
                    hl.AIActionsAction = { fg = c.green }
                    hl.AIActionsInActiveContext = { link = "Comment" }
                    hl.AIActionsActiveContext = { fg = c.red, bold = true }
                    hl.Folded = { fg = c.blue, bg = "" }
                    hl.HackedPortalNC = { fg = c.terminal_black, bg = c.blue7 }
                    hl.HackedPortal = { fg = c.bg_highlight, bg = c.green }
                    hl.HackedPortalEdgeNC = { fg = c.blue7 }
                    hl.HackedPortalEdge = { fg = c.green }
                    -- statusbar
                    hl.Statusbar = { fg = c.bg_highlight, bg = c.red, bold = true }
                    hl.StatusbarEdge = { fg = c.red }
                end,
            })

            vim.cmd.colorscheme("tokyonight-night")
        end,
    },
    {
        "catppuccin/nvim",
        name = "catppuccin",
        enabled = false,
        priority = 1000,
        lazy = false,
        config = function()
            require("catppuccin").setup({
                custom_highlights = function(colors)
                    return {
                        MiniTablineTabpagesection = { fg = colors.green, style = { "bold" } },
                        HighlightYank = { bg = colors.mauve },
                        AIActionsHeader = { fg = colors.lavender, style = { "bold" } }, -- mauve
                        AIActionsAction = { fg = colors.lavender },
                        AIActionsInActiveContext = { link = "Comment" },
                        AIActionsActiveContext = { fg = colors.peach, style = { "bold" } },
                        Folded = { fg = colors.peach, bg = "" },
                    }
                end,
            })
            vim.cmd.colorscheme("catppuccin")
        end,
    },
    {
        "rktjmp/lush.nvim",
        -- if you wish to use your own colorscheme:
    },
    {
        dir = os.getenv("HOME") .. "/.config/nvim/lua/themes/focus",
        enabled = false,
        lazy = false,
        priority = 1000,
        config = function()
            vim.cmd("colorscheme focus")
        end,
    },
}
