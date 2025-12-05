local M = {
    config = function()
        local Color = require("color")

        require("catppuccin").setup({
            flavour = "mocha",
            custom_highlights = function(colors)
                return {
                    ["Winbar"] = { bg = Color:from_hex(colors.base):lighten(2):hex() },
                    ["StatusLine"] = { bg = Color:from_hex(colors.base):lighten(2):hex() },
                    ["StatuslineNC"] = { bg = "" },
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
                        fg = "#89b4fb",
                        bg = Color:from_hex(colors.base):lighten(8):hex(),
                    },
                    ["MiniStatuslineModeReplaceSeparator"] = {
                        fg = "#f38ba9",
                        bg = Color:from_hex(colors.base):lighten(8):hex(),
                    },
                    ["MiniStatuslineModeVisualSeparator"] = {
                        fg = "#cba6f8",
                        bg = Color:from_hex(colors.base):lighten(8):hex(),
                    },
                    ["MiniStatuslineModeInsertSeparator"] = {
                        fg = "#a6e3a2",
                        bg = Color:from_hex(colors.base):lighten(8):hex(),
                    },
                    ["MiniStatuslineModeCommandSeparator"] = {
                        fg = "#fab388",
                        bg = Color:from_hex(colors.base):lighten(8):hex(),
                    },
                }
            end,
        })

        vim.cmd.colorscheme("catppuccin")
    end,
}

return M
