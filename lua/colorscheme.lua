local kanagawa = function()
    require("kanagawa").setup({
        compile = false, -- enable compiling the colorscheme
        undercurl = true, -- enable undercurls
        commentStyle = { italic = true },
        functionStyle = {},
        keywordStyle = { italic = true },
        statementStyle = { bold = true },
        typeStyle = {},
        transparent = false, -- do not set background color
        dimInactive = false, -- dim inactive window `:h hl-NormalNC`
        terminalColors = true, -- define vim.g.terminal_color_{0,17}
        colors = { -- add/modify theme and palette colors
            palette = {},
            theme = { wave = {}, lotus = {}, dragon = {}, all = {} },
        },
        overrides = function(colors) -- add/modify highlights
            local theme = colors.theme
            return {
                NormalFloat = { bg = "none" },
                FloatBorder = { bg = "" },
                FloatTitle = { bg = "none" },
                Pmenu = { fg = theme.ui.shade0, bg = "" },
                PmenuSel = { bg = theme.ui.shade0 },
                PmenuSbar = { bg = theme.ui.bg_m1 },
                PmenuThumb = { bg = theme.ui.bg_p2 },
                BlinkCmpMenuBorder = { bg = "" },
                BlinkCmpMenu = { bg = "" },
                Folded = { bg = "" },
                LineNr = { bg = "" },
                SignColumn = { bg = "" },
                TreesitterContextLineNumber = { bg = "" },
                MiniIconsGreen = { fg = "#89a96c" },
                MiniIconsOrange = { fg = "#cd8c64" },
                StatusLineNC = { bg = "" },
                StatusLine = { bg = "#1d1b1b" },
            }
        end,
        theme = "dragon",
        background = {
            dark = "dragon",
            light = "lotus",
        },
    })

    vim.cmd.colorscheme("kanagawa")
end

vim.cmd.colorscheme("synth")
