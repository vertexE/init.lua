return {
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        enabled = true,
        config = function()
            require("catppuccin").setup({
                flavour = "auto", -- latte, frappe, macchiato, mocha
                background = { -- :h background
                    light = "latte",
                    dark = "mocha",
                },
                transparent_background = false, -- disables setting the background color.
                show_end_of_buffer = false, -- shows the '~' characters after the end of buffers
                term_colors = false, -- sets terminal colors (e.g. `g:terminal_color_0`)
                dim_inactive = {
                    enabled = true, -- dims the background color of inactive window
                    shade = "dark",
                    percentage = 0.15, -- percentage of the shade to apply to the inactive window
                },
                no_italic = false, -- Force no italic
                no_bold = false, -- Force no bold
                no_underline = false, -- Force no underline
                styles = { -- Handles the styles of general hi groups (see `:h highlight-args`):
                    comments = { "italic" }, -- Change the style of comments
                    conditionals = {},
                    loops = {},
                    functions = {},
                    keywords = { "bold" },
                    strings = {},
                    variables = {},
                    numbers = {},
                    booleans = {},
                    properties = {},
                    types = {},
                    operators = {},
                    -- miscs = {}, -- Uncomment to turn off hard-coded styles
                },
                color_overrides = {
                    mocha = {
                        rosewater = "#f5e0dc",
                        flamingo = "#f2cdcd",
                        pink = "#f5c2e7",
                        mauve = "#b3b7ee",
                        red = "#f38ba8",
                        maroon = "#eba0ac",
                        peach = "#fab387",
                        yellow = "#f9e2af",
                        green = "#a8aa4b",
                        teal = "#ffafc5",
                        sky = "#89dceb",
                        sapphire = "#74c7ec",
                        blue = "#cba6f7",
                        lavender = "#b4befe",
                        text = "#c0c0c0",
                        subtext1 = "#bac2de",
                        subtext0 = "#a6adc8",
                        overlay2 = "#f6c177",
                        overlay1 = "#7f849c",
                        overlay0 = "#6c7086",
                        surface2 = "#585b70",
                        surface1 = "#45475a",
                        surface0 = "#313244",
                        base = "#151320",
                        mantle = "#181825",
                        crust = "#11111b",
                    },
                },
                custom_highlights = function(colors)
                    return {
                        Pmenu = { fg = colors.subtext1, bg = colors.base },
                        Visual = { bg = "#2a2345" },
                        HighlightYank = { bg = colors.mauve },
                        Comment = { fg = "#494c5e" },
                        Folded = { fg = colors.peach, bg = "" },
                        -- -- copilot
                        AIActionsHeader = { fg = colors.lavender, style = { "bold" } },
                        AIActionsAction = { fg = colors.mauve },
                        AIActionsInActiveContext = { link = "Comment" },
                        AIActionsActiveContext = { fg = colors.teal, style = { "bold" } },
                        -- -- hacked
                        HackedPortalNC = { fg = colors.surface0, bg = colors.blue },
                        HackedPortal = { fg = colors.surface0, bg = colors.green },
                        HackedPortalEdgeNC = { fg = colors.blue },
                        HackedPortalEdge = { fg = colors.green },
                        -- -- statusbar
                        Statusbar = { fg = colors.surface1, bg = colors.blue, style = { "bold" } },
                        StatusbarEdge = { fg = colors.blue },
                        -- -- plugins
                        NamuFilter = { fg = colors.red },
                    }
                end,
                default_integrations = true,
                integrations = {
                    blink_cmp = true,
                    gitsigns = true,
                    nvimtree = true,
                    treesitter = true,
                    notify = true,
                    mini = {
                        enabled = true,
                        indentscope_color = "",
                    },
                },
            })

            vim.cmd.colorscheme("catppuccin")
        end,
    },
    {
        "folke/tokyonight.nvim",
        lazy = false,
        enabled = false,
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
}
