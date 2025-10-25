require("synth").setup({
    override_hl = function(colors)
        return {
            -- default
            ["StatusLineSeparator"] = { fg = colors.surface:lighten():hex() },
            ["StatusLineSeparatorContent"] = { fg = colors.steel:lighten():hex(), bg = colors.surface:lighten():hex() },
            -- lsp
            ["StatusLineSeparatorLsp"] = { fg = colors.green:hex(), bg = colors.surface:lighten():hex() },
            -- mode
            ["MiniStatuslineModeNormalSeparator"] = {
                fg = colors.primary:fade(15):hex(),
                bg = colors.surface:lighten():hex(),
            },
            ["MiniStatuslineModeReplaceSeparator"] = { fg = colors.red:hex(), bg = colors.surface:lighten():hex() },
            ["MiniStatuslineModeVisualSeparator"] = { fg = colors.purple:hex(), bg = colors.surface:lighten():hex() },
            ["MiniStatuslineModeInsertSeparator"] = { fg = colors.brown:hex(), bg = colors.surface:lighten():hex() },
            ["MiniStatuslineModeCommandSeparator"] = { fg = colors.orange:hex(), bg = colors.surface:lighten():hex() },
        }
    end,
})

vim.cmd.colorscheme("synth")
