local M = {}

local Color = require("core.ui.color")

M.setup = function()
    local transparent = false

    -- core palette
    local ocean_100 = Color:from_hex("#406277")
    local ocean_200 = Color:from_hex("#5A8BAA")
    local ocean_300 = Color:from_hex("#8DB3C9")
    local ocean_400 = Color:from_hex("#5e81ac")

    local surface = Color:from_hex("#fefaf4")
    local ink = Color:from_hex("#4C4F59")
    local chalk = Color:from_hex("#F2F0E9")

    local text_100 = ink
    local text_200 = ink:lighten(15)
    local text_300 = ink:lighten(25)

    local stone_100 = Color:from_hex("#8F8A7D")
    local stone_200 = Color:from_hex("#C8C4B9")
    local stone_300 = Color:from_hex("#E5E2DA")

    -- colors
    local rose = Color:from_hex("#D98686")
    local peach = Color:from_hex("#E5AB89")
    local gold = Color:from_hex("#F0DFAF")
    local sage = Color:from_hex("#A0BCA7")
    local sky = Color:from_hex("#85AED3")
    local lilac = Color:from_hex("#BEA6D8")

    vim.api.nvim_set_hl(0, "MiniIconsGrey", { fg = stone_100:hex() })
    vim.api.nvim_set_hl(0, "MiniIconsAzure", { fg = ocean_200:hex() })
    vim.api.nvim_set_hl(0, "MiniIconsPurple", { fg = lilac:hex() })
    vim.api.nvim_set_hl(0, "MiniIconsCyan", { fg = ocean_300:hex() })
    vim.api.nvim_set_hl(0, "MiniIconsRed", { fg = rose:hex() })
    vim.api.nvim_set_hl(0, "MiniIconsGreen", { fg = sage:hex() })
    vim.api.nvim_set_hl(0, "MiniIconsOrange", { fg = peach:hex() })
    vim.api.nvim_set_hl(0, "MiniIconsYellow", { fg = gold:hex() })
    vim.api.nvim_set_hl(0, "MiniIconsBlue", { fg = sky:hex() })

    vim.api.nvim_set_hl(0, "@none", { fg = "", bg = "" })

    -- nvim
    -- ctermbg
    vim.api.nvim_set_hl(0, "Normal", { bg = transparent and "" or surface:hex(), fg = text_100:hex() })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = transparent and "" or surface:hex(), fg = text_100:hex() })
    vim.api.nvim_set_hl(0, "Visual", { bg = chalk:hex() })
    vim.api.nvim_set_hl(0, "HighlightYank", { bg = stone_300:hex() })
    vim.api.nvim_set_hl(0, "StatusLine", { bg = transparent and "" or surface:hex() })
    vim.api.nvim_set_hl(0, "StatusLineNC", { bg = transparent and "" or surface:hex() })
    vim.api.nvim_set_hl(0, "WinBar", { bg = transparent and "" or surface:lighten(1):hex() })
    vim.api.nvim_set_hl(0, "WinBarNC", { link = "WinBar" })
    vim.api.nvim_set_hl(0, "Pmenu", { bg = transparent and "" or surface:hex(), fg = stone_100:hex() })
    vim.api.nvim_set_hl(0, "PmenuThumb", {})
    vim.api.nvim_set_hl(0, "FloatBorder", { fg = stone_100:hex() })
    vim.api.nvim_set_hl(0, "BlinkCmpDocBorder", { fg = stone_300:hex() })
    vim.api.nvim_set_hl(0, "BlinkCmpMenuBorder", { fg = stone_300:hex() })
    vim.api.nvim_set_hl(0, "MiniIndentscopeSymbol", { fg = stone_100:hex() })
    vim.api.nvim_set_hl(0, "WinSeparator", { fg = stone_100:hex() })
    vim.api.nvim_set_hl(0, "Folded", { fg = stone_200:darken(5):hex() })
    vim.api.nvim_set_hl(0, "QuickFixLine", { fg = ocean_400:hex() })
    vim.api.nvim_set_hl(0, "MatchParen", { bg = stone_300:hex() })
    vim.api.nvim_set_hl(0, "Cursor", { bg = lilac:hex() })
    vim.api.nvim_set_hl(0, "CursorLine", {})

    -- lsp links
    vim.api.nvim_set_hl(0, "Constant", { fg = lilac:hex() })
    vim.api.nvim_set_hl(0, "Identifier", { fg = sage:hex() })
    vim.api.nvim_set_hl(0, "Special", { fg = sage:fade():hex() })
    vim.api.nvim_set_hl(0, "Type", { fg = sage:hex() })
    vim.api.nvim_set_hl(0, "String", { fg = sage:hex() })
    vim.api.nvim_set_hl(0, "Function", { fg = sky:hex() })
    vim.api.nvim_set_hl(0, "Delimiter", { fg = text_300:hex() })
    vim.api.nvim_set_hl(0, "Statement", { fg = text_200:hex() })
    vim.api.nvim_set_hl(0, "Keyword", { fg = rose:hex() })
    vim.api.nvim_set_hl(0, "Comment", { italic = true, fg = stone_200:hex() })

    -- lsp warnings
    vim.api.nvim_set_hl(0, "DiagnosticUnnecessary", { fg = chalk:darken():hex() })
    vim.api.nvim_set_hl(0, "DiagnosticError", { fg = rose:hex() })
    vim.api.nvim_set_hl(0, "DiagnosticHint", { fg = gold:hex() })
    vim.api.nvim_set_hl(0, "DiagnosticWarn", { fg = gold:darken(22):hex() })
    vim.api.nvim_set_hl(0, "DiagnosticInfo", { fg = peach:hex() })
    vim.api.nvim_set_hl(0, "DiagnosticUnderlineError", { fg = "", bg = "" })
    vim.api.nvim_set_hl(0, "DiagnosticUnderlineWarn", { fg = "", bg = "" })
    vim.api.nvim_set_hl(0, "DiagnosticUnderlineOk", { fg = "", bg = "" })
    vim.api.nvim_set_hl(0, "DiagnosticUnderlineHint", { fg = "", bg = "" })
    vim.api.nvim_set_hl(0, "DiagnosticUnderlineInfo", { fg = "", bg = "" })

    -- lsp semantics
    vim.api.nvim_set_hl(0, "@text", { fg = text_100:hex() })
    vim.api.nvim_set_hl(0, "@variable", { fg = text_200:hex() })
    vim.api.nvim_set_hl(0, "@function", { fg = sky:hex() })
    vim.api.nvim_set_hl(0, "@property", { fg = ocean_100:hex() })

    -- lua
    vim.api.nvim_set_hl(0, "@lsp.type.method.lua", {})
    vim.api.nvim_set_hl(0, "@lsp.type.property.lua", { fg = ocean_200:hex() })
    -- vim.api.nvim_set_hl(0, "@lsp.type.method.lua", { fg = sky:hex() })

    -- tsx
    vim.api.nvim_set_hl(0, "@tag", { link = "@variable" })
    vim.api.nvim_set_hl(0, "@tag.builtin.tsx", { fg = sky:hex() })
    vim.api.nvim_set_hl(0, "@tag.attribute.tsx", { fg = stone_200:hex() })

    -- ts

    -- rust

    -- golang
    vim.api.nvim_set_hl(0, "@variable.parameter.go", {})

    -- markdown
    vim.api.nvim_set_hl(0, "@markup.strong", { fg = rose:hex(), bold = true })
    vim.api.nvim_set_hl(0, "@markup.italic", { fg = sage:hex(), italic = true })
    vim.api.nvim_set_hl(0, "@markup.heading.1.markdown", { fg = peach:hex(), bold = true })

    -- git
    vim.api.nvim_set_hl(0, "Changed", { fg = gold:darken(15):hex() })
    vim.api.nvim_set_hl(0, "Removed", { fg = rose:saturate(5):hex() })
    vim.api.nvim_set_hl(0, "Added", { fg = sage:saturate(35):darken(30):hex() })
    vim.api.nvim_set_hl(0, "DiffChange", { link = "Comment" })
    vim.api.nvim_set_hl(0, "DiffText", { fg = peach:hex(), bg = gold:hex() })
    vim.api.nvim_set_hl(0, "DiffDelete", { fg = rose:hex(), bg = rose:lighten(16):hex() })
    vim.api.nvim_set_hl(0, "DiffAdd", { bg = sage:lighten(16):hex() })

    vim.api.nvim_set_hl(0, "NeogitDiffDelete", { link = "DiffDelete" })
    vim.api.nvim_set_hl(0, "NeogitDiffAdd", { link = "DiffAdd" })
    vim.api.nvim_set_hl(0, "NeogitDiffDeleteHighlight", { link = "DiffDelete" })
    vim.api.nvim_set_hl(0, "NeogitDiffAddHighlight", { link = "DiffAdd" })

    vim.api.nvim_set_hl(0, "NeogitDiffContext", { link = "Normal" })
    vim.api.nvim_set_hl(0, "NeogitDiffContextHighlight", { link = "Normal" })
    vim.api.nvim_set_hl(0, "NeogitDiffHeader", { link = "Normal" })
    vim.api.nvim_set_hl(0, "NeogitDiffContextCursor", { link = "Normal" })

    vim.api.nvim_set_hl(0, "NeogitDiffDeleteCursor", { link = "DiffDelete" })
    vim.api.nvim_set_hl(0, "NeogitDiffAddCursor", { link = "DiffAdd" })

    --  TODO: test
    --  FIXME: test
    --  BUG: test
    --  INFO: test
    --  HACK: test
    --  PERF: test
    -- plugins
    vim.api.nvim_set_hl(0, "TodoBgTODO", { fg = text_100:hex(), bg = sage:saturate(15):hex(), bold = true })
    vim.api.nvim_set_hl(0, "TodoFgTODO", { fg = sage:hex() })
    vim.api.nvim_set_hl(0, "TodoSignTODO", { fg = sage:hex() })
    vim.api.nvim_set_hl(0, "AIActionsHeader", { link = "@text" })
    vim.api.nvim_set_hl(0, "AIActionsInActiveContext", { link = "@comment" })
    vim.api.nvim_set_hl(0, "AIActionsActiveContext", { fg = peach:hex() })

    -- vim.api.nvim_set_hl(0, "HackedPortalNC", { fg = gray_500:hex(), bg = gray_900:hex() })
    -- vim.api.nvim_set_hl(0, "HackedPortal", { fg = gray_900:hex(), bg = orange:hex() })
    -- vim.api.nvim_set_hl(0, "HackedPortalEdgeNC", { fg = gray_900:hex() })
    -- vim.api.nvim_set_hl(0, "HackedPortalEdge", { fg = orange:hex() })

    vim.api.nvim_set_hl(0, "SnacksBackdrop", { bg = transparent and "" or surface:fade(8):hex() })

    vim.api.nvim_set_hl(0, "MiniStatuslineModeNormal", { fg = text_100:hex(), bg = sky:hex(), bold = true })
    vim.api.nvim_set_hl(0, "MiniStatuslineModeReplace", { fg = text_100:hex(), bg = rose:hex(), bold = true })
    vim.api.nvim_set_hl(0, "MiniStatuslineModeVisual", { fg = text_100:hex(), bg = lilac:hex(), bold = true })
    vim.api.nvim_set_hl(0, "MiniStatuslineModeInsert", { fg = text_100:hex(), bg = sage:hex(), bold = true })
    vim.api.nvim_set_hl(0, "MiniStatuslineModeCommand", { fg = text_100:hex(), bg = peach:hex(), bold = true })
end

return M
