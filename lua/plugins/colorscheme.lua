local M = {
    config = function()
        local Color = require("color")

        require("catppuccin").setup({
            flavour = "mocha",
            color_overrides = {
                all = {
                    -- Simplified warm accents (brighter, more contrast)
                    rosewater = "#e0c4ab", -- lighter earthy tan
                    flamingo = "#e0c4ab", -- merged with rosewater
                    pink = "#d9b5a3", -- brighter dusty rose-brown
                    mauve = "#b8a692", -- lighter earthy taupe
                    red = "#e09a82", -- brighter terracotta/clay
                    maroon = "#e09a82", -- merged with red
                    peach = "#e5b580", -- brighter sandy brown
                    yellow = "#dac9a5", -- lighter wheat/sand

                    -- Green/blue palette - brighter pine forest
                    green = "#8db599", -- brighter sage pine
                    teal = "#7ba38e", -- brighter forest teal
                    sky = "#7ba38e", -- merged with teal
                    sapphire = "#6a9485", -- brighter evergreen
                    blue = "#6a9485", -- merged with sapphire
                    lavender = "#9aac9d", -- lighter misty pine

                    -- Text hierarchy - higher contrast
                    text = "#e5ede7", -- brighter off-white with green hint
                    subtext1 = "#c8d4ca", -- lighter muted sage
                    subtext0 = "#acbcb0", -- lighter pale pine

                    -- Surfaces - more defined steps
                    -- overlay2 = "#8a9891",
                    -- overlay1 = "#727c75",
                    -- overlay0 = "#5c665f",
                    overlay2 = "#9aaa9f", -- brightened
                    overlay1 = "#849188", -- brightened (line numbers)
                    overlay0 = "#6e7973", -- brightened
                    surface2 = "#455049",
                    surface1 = "#313b36",
                    surface0 = "#232d28",

                    -- Backgrounds - your requested green hints
                    base = "#152326", -- deep forest base
                    mantle = "#111d1f", -- darker forest
                    crust = "#0d1517", -- almost black with green
                },
            },
            custom_highlights = function(colors)
                return {
                    ["LineNr"] = { fg = colors.overlay0 },
                    ["Winbar"] = { bg = Color:from_hex(colors.base):lighten(2):hex() },
                    ["StatusLine"] = { bg = Color:from_hex(colors.base):lighten(2):hex() },
                    ["StatusLineNC"] = { bg = "" },
                    ["CommentItalic"] = { fg = colors.overlay1, italic = true },
                    ["StatusLineSeparator"] = { fg = Color:from_hex(colors.base):lighten(8):hex() },
                    ["StatusLineSeparatorContent"] = {
                        fg = colors.subtext1,
                        bg = Color:from_hex(colors.base):lighten(8):hex(),
                    },
                    ["StatuslineSeparatorLsp"] = {
                        fg = colors.green,
                        bg = Color:from_hex(colors.base):lighten(8):hex(),
                    },
                    ["MiniStatuslineModeNormalSeparator"] = {
                        fg = "#6a9486",
                        bg = Color:from_hex(colors.base):lighten(8):hex(),
                    },
                    ["MiniStatuslineModeReplaceSeparator"] = {
                        fg = "#e09a83",
                        bg = Color:from_hex(colors.base):lighten(8):hex(),
                    },
                    ["MiniStatuslineModeVisualSeparator"] = {
                        fg = "#b8a693",
                        bg = Color:from_hex(colors.base):lighten(8):hex(),
                    },
                    ["MiniStatuslineModeInsertSeparator"] = {
                        fg = "#8db59a",
                        bg = Color:from_hex(colors.base):lighten(8):hex(),
                    },
                    ["MiniStatuslineModeCommandSeparator"] = {
                        fg = "#e5b581",
                        bg = Color:from_hex(colors.base):lighten(8):hex(),
                    },
                }
            end,
        })

        vim.cmd.colorscheme("catppuccin")
    end,
}

return M
