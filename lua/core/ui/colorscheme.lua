local M = {}

local Color = require("core.ui.color")

-- HackedPortalNC = { fg = colors.surface0, bg = colors.blue },
-- HackedPortal = { fg = colors.surface0, bg = colors.green },
-- HackedPortalEdgeNC = { fg = colors.blue },
-- HackedPortalEdge = { fg = colors.green },

M.setup = function()
    -- vim.cmd.colorscheme("default") ?? do I need this?

    local transparent = true
    -- #c17c74
    -- #eaac8b
    -- #BD3685
    -- #d7bea8
    -- #f29559
    -- #2E3440
    -- vim.print(Color:from_hex("#304363"):saturate(10):hex()) -- #566175, #274066
    -- local accent = Color:from_hex("#5E81AC"):saturate(30):darken(15)
    -- local accent = Color:from_hex("#f29559"):darken(25)
    -- local accent = Color:from_hex("#BD3685") -- :complement()
    local accent = Color:from_hex("#88C0D0"):saturate(18):darken(25)

    local step = 11
    local accent500 = accent
    local accent400 = accent500:lighten(step)
    local accent300 = accent400:lighten(step)
    local accent200 = accent300:lighten(step)
    local accent100 = accent200:lighten(step)
    -- accent500
    local accent600 = accent500:darken(step)
    local accent700 = accent600:darken(step)
    local accent800 = accent700:darken(step)
    local accent900 = accent800:darken(step)

    local base = accent:fade(35):darken()
    local base500 = base:lighten(step)
    local base400 = base500:lighten(step)
    local base300 = base400:lighten(step)
    local base200 = base300:lighten(step)
    local base100 = base200:lighten(step)

    local base600 = base500:darken(step)
    local base700 = base600:darken(step)
    local base800 = base700:darken(step)
    local base900 = base800:darken(step)
    local surface = base900:darken(4)

    vim.api.nvim_set_hl(0, "@base100", { fg = base100:hex() })
    vim.api.nvim_set_hl(0, "@base200", { fg = base200:hex() })
    vim.api.nvim_set_hl(0, "@base300", { fg = base300:hex() })
    vim.api.nvim_set_hl(0, "@base400", { fg = base400:hex() })
    vim.api.nvim_set_hl(0, "@base500", { fg = base500:hex() })
    vim.api.nvim_set_hl(0, "@base600", { fg = base600:hex() })
    vim.api.nvim_set_hl(0, "@base700", { fg = base700:hex() })
    vim.api.nvim_set_hl(0, "@base800", { fg = base800:hex() })
    vim.api.nvim_set_hl(0, "@base900", { fg = base900:hex() })

    vim.api.nvim_set_hl(0, "@surface", { fg = surface:hex() })

    vim.api.nvim_set_hl(0, "@accent100", { fg = accent100:hex() })
    vim.api.nvim_set_hl(0, "@accent200", { fg = accent200:hex() })
    vim.api.nvim_set_hl(0, "@accent300", { fg = accent300:hex() })
    vim.api.nvim_set_hl(0, "@accent400", { fg = accent400:hex() })
    vim.api.nvim_set_hl(0, "@accent500", { fg = accent500:hex() })
    vim.api.nvim_set_hl(0, "@accent600", { fg = accent600:hex() })
    vim.api.nvim_set_hl(0, "@accent700", { fg = accent700:hex() })
    vim.api.nvim_set_hl(0, "@accent800", { fg = accent800:hex() })
    vim.api.nvim_set_hl(0, "@accent900", { fg = accent900:hex() })

    vim.api.nvim_set_hl(0, "@none", { fg = "", bg = "" })
    -- core colors
    local green = Color:from_hex("#a9b66b")
    local red0 = Color:from_hex("#eb6f92")
    local red1 = Color:from_hex("#da627d")
    local yellow = Color:from_hex("#EBCB8B")
    local orange = Color:from_hex("#f77a4e")
    local blue = Color:from_hex("#548de2")

    -- blue options?
    -- #0d6cfb
    -- #2070e8
    -- #99b9ea
    -- #548de2

    -- nvim
    -- ctermbg
    vim.api.nvim_set_hl(0, "Normal", { bg = transparent and "" or surface:hex(), fg = base200:hex() })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = transparent and "" or surface:hex(), fg = base200:hex() })
    vim.api.nvim_set_hl(0, "Visual", { bg = base400:darken(50):hex() })
    vim.api.nvim_set_hl(0, "HighlightYank", { bg = accent300:hex() })
    vim.api.nvim_set_hl(0, "StatusLine", { bg = transparent and "" or surface:hex() })
    vim.api.nvim_set_hl(0, "StatusLineNC", { bg = transparent and "" or surface:hex() })
    vim.api.nvim_set_hl(0, "WinBar", { bg = transparent and "" or surface:lighten(1):hex() })
    vim.api.nvim_set_hl(0, "WinBarNC", { link = "WinBar" })
    vim.api.nvim_set_hl(0, "Pmenu", { bg = transparent and "" or surface:hex(), fg = base700:hex() })
    vim.api.nvim_set_hl(0, "PmenuThumb", { fg = base700:hex() })
    vim.api.nvim_set_hl(0, "FloatBorder", { fg = base700:hex() })
    vim.api.nvim_set_hl(0, "BlinkCmpDocBorder", { fg = base700:hex() })
    vim.api.nvim_set_hl(0, "MiniIndentscopeSymbol", { fg = base800:hex() })
    vim.api.nvim_set_hl(0, "WinSeparator", { fg = base800:hex() })
    vim.api.nvim_set_hl(0, "Folded", { fg = base800:hex() })

    -- lsp links
    vim.api.nvim_set_hl(0, "Constant", { fg = base500:hex() })
    vim.api.nvim_set_hl(0, "Identifier", { fg = base500:hex() })
    vim.api.nvim_set_hl(0, "Special", { fg = accent400:hex() })
    vim.api.nvim_set_hl(0, "Type", { fg = yellow:darken():hex() })
    vim.api.nvim_set_hl(0, "String", { fg = green:saturate():hex() })
    vim.api.nvim_set_hl(0, "Function", { fg = accent500:hex() })
    vim.api.nvim_set_hl(0, "Statement", { fg = base600:hex() })
    vim.api.nvim_set_hl(0, "Comment", { italic = true, fg = base700:hex() })

    -- lsp warnings
    vim.api.nvim_set_hl(0, "DiagnosticUnnecessary", { fg = base700:darken():hex() })
    vim.api.nvim_set_hl(0, "DiagnosticError", { fg = red1:hex() })
    vim.api.nvim_set_hl(0, "DiagnosticHint", { fg = yellow:hex() })
    vim.api.nvim_set_hl(0, "DiagnosticUnderlineError", { fg = "", bg = "" })
    vim.api.nvim_set_hl(0, "DiagnosticUnderlineWarn", { fg = "", bg = "" })
    vim.api.nvim_set_hl(0, "DiagnosticUnderlineOk", { fg = "", bg = "" })
    vim.api.nvim_set_hl(0, "DiagnosticUnderlineHint", { fg = "", bg = "" })
    vim.api.nvim_set_hl(0, "DiagnosticUnderlineInfo", { fg = "", bg = "" })

    -- lsp semantics
    vim.api.nvim_set_hl(0, "@text", { fg = base300:hex() })
    vim.api.nvim_set_hl(0, "@variable", { fg = base200:hex() })
    vim.api.nvim_set_hl(0, "@function", { fg = base500:hex() })
    vim.api.nvim_set_hl(0, "@property", { fg = base200:hex() })

    -- lua
    vim.api.nvim_set_hl(0, "@lsp.type.method.lua", {})

    -- tsx
    vim.api.nvim_set_hl(0, "@tag", { link = "@variable" })
    vim.api.nvim_set_hl(0, "@tag.builtin.tsx", { fg = base600:hex() })
    vim.api.nvim_set_hl(0, "@tag.attribute.tsx", { fg = base700:hex() })

    -- ts

    -- rust

    -- golang

    -- git
    vim.api.nvim_set_hl(0, "Changed", { fg = yellow:darken(15):hex() })
    vim.api.nvim_set_hl(0, "Removed", { fg = red0:saturate(5):hex() })
    vim.api.nvim_set_hl(0, "Added", { fg = green:saturate(35):darken(30):hex() })
    vim.api.nvim_set_hl(0, "DiffChange", { fg = yellow:fade(70):hex(), bg = yellow:darken(45):hex() })
    vim.api.nvim_set_hl(0, "DiffText", { fg = yellow:fade(70):hex(), bg = yellow:darken(45):hex() })
    vim.api.nvim_set_hl(0, "DiffDelete", { fg = red1:hex(), bg = red1:fade(20):darken(50):hex() })
    vim.api.nvim_set_hl(0, "DiffAdd", { fg = green:hex(), bg = green:darken(35):hex() })

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
    vim.api.nvim_set_hl(0, "TodoBgTODO", { fg = base900:hex(), bg = green:saturate(15):hex(), bold = true })
    vim.api.nvim_set_hl(0, "TodoFgTODO", { fg = green:hex() })
    vim.api.nvim_set_hl(0, "TodoSignTODO", { fg = green:hex() })
    vim.api.nvim_set_hl(0, "AIActionsHeader", { link = "@text" })
    vim.api.nvim_set_hl(0, "AIActionsInActiveContext", { link = "@comment" })
    vim.api.nvim_set_hl(0, "AIActionsActiveContext", { fg = orange:hex() })

    vim.api.nvim_set_hl(0, "HackedPortalNC", { fg = base700:hex(), bg = base800:hex() })
    vim.api.nvim_set_hl(0, "HackedPortal", { fg = base800:hex(), bg = orange:hex() })
    vim.api.nvim_set_hl(0, "HackedPortalEdgeNC", { fg = base800:hex() })
    vim.api.nvim_set_hl(0, "HackedPortalEdge", { fg = orange:hex() })

    vim.api.nvim_set_hl(0, "SnacksBackdrop", { bg = transparent and "" or surface:hex() })

    vim.api.nvim_set_hl(0, "MiniStatuslineModeNormal", { fg = accent800:hex(), bg = base500:hex(), bold = true })
    vim.api.nvim_set_hl(0, "MiniStatuslineModeReplace", { fg = accent800:hex(), bg = red1:hex(), bold = true })
    vim.api.nvim_set_hl(0, "MiniStatuslineModeVisual", { fg = accent800:hex(), bg = blue:hex(), bold = true })
    vim.api.nvim_set_hl(0, "MiniStatuslineModeInsert", { fg = accent800:hex(), bg = green:hex(), bold = true })
    vim.api.nvim_set_hl(0, "MiniStatuslineModeCommand", { fg = accent800:hex(), bg = orange:hex(), bold = true })
end

M.setup()

return M
