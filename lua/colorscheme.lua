require("synth").setup({
    override_hl = function(colors)
        return {
            ["StatusLineSeparator"] = { fg = colors.surface:lighten():hex() },
            ["StatusLineSeparatorContent"] = { fg = colors.steel:lighten():hex(), bg = colors.surface:lighten():hex() },
        }
    end,
})

vim.cmd.colorscheme("synth")
