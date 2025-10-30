require("synth").setup({
    override_hl = function(colors)
        return {
            -- default
            ["StatusLineSeparator"] = { fg = colors.surface:lighten(8):hex() },
            ["StatusLineSeparatorContent"] = {
                fg = colors.steel:lighten(22):hex(),
                bg = colors.surface:lighten(8):hex(),
            },
            -- lsp
            ["StatusLineSeparatorLsp"] = { fg = colors.green:hex(), bg = colors.surface:lighten(8):hex() },
            -- mode
            ["MiniStatuslineModeNormalSeparator"] = {
                fg = colors.primary:fade(15):hex(),
                bg = colors.surface:lighten(8):hex(),
            },
            ["MiniStatuslineModeReplaceSeparator"] = { fg = colors.red:hex(), bg = colors.surface:lighten(8):hex() },
            ["MiniStatuslineModeVisualSeparator"] = { fg = colors.purple:hex(), bg = colors.surface:lighten(8):hex() },
            ["MiniStatuslineModeInsertSeparator"] = { fg = colors.brown:hex(), bg = colors.surface:lighten(8):hex() },
            ["MiniStatuslineModeCommandSeparator"] = { fg = colors.orange:hex(), bg = colors.surface:lighten(8):hex() },
        }
    end,
})

vim.cmd.colorscheme("synth")
