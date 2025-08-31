local M = {}

local Color = require("core.ui.color")

M.setup = function()
    local transparent = true
    local accent = Color:from_hex("#88C0D0"):saturate(18):darken(25)

    -- core palette
    local frost_100 = Color:from_hex("#88c0d0")
    local frost_200 = Color:from_hex("#81a1c1")
    local frost_300 = Color:from_hex("#8fbcbb")
    local frost_400 = Color:from_hex("#5e81ac")

    local text_300 = Color:from_hex("#d8dee9"):darken(25)
    local text_200 = Color:from_hex("#e5e9f0"):darken(15)
    local text_100 = Color:from_hex("#eceff4")

    local base_900 = Color:from_hex("#203040")
    local base_800 = Color:from_hex("#2e3440")
    local base_700 = Color:from_hex("#3b4252")
    local base_600 = Color:from_hex("#434c5e")
    local base_500 = Color:from_hex("#4c566a")
    local base_400 = base_500:lighten(15)
    local base_300 = base_400:lighten(15)

    -- colors
    local red = Color:from_hex("#bf616a")
    local yellow = Color:from_hex("#ebcb8b")
    local blue = Color:from_hex("#5e81ac")
    local green = Color:from_hex("#a3be8c")
    local orange = Color:from_hex("#D08770")
    local purple = Color:from_hex("#b48ead")

    vim.api.nvim_set_hl(0, "@0text100", { fg = text_100:hex() })
    vim.api.nvim_set_hl(0, "@0text200", { fg = text_200:hex() })
    vim.api.nvim_set_hl(0, "@0text300", { fg = text_300:hex() })
    vim.api.nvim_set_hl(0, "@0frost100", { fg = frost_100:hex() })
    vim.api.nvim_set_hl(0, "@0frost200", { fg = frost_200:hex() })
    vim.api.nvim_set_hl(0, "@0frost300", { fg = frost_300:hex() })
    vim.api.nvim_set_hl(0, "@0frost400", { fg = frost_400:hex() })
    vim.api.nvim_set_hl(0, "@0base300", { fg = base_300:hex() })
    vim.api.nvim_set_hl(0, "@0base400", { fg = base_400:hex() })
    vim.api.nvim_set_hl(0, "@0base500", { fg = base_500:hex() })
    vim.api.nvim_set_hl(0, "@0base600", { fg = base_600:hex() })
    vim.api.nvim_set_hl(0, "@0base700", { fg = base_700:hex() })
    vim.api.nvim_set_hl(0, "@0base800", { fg = base_800:hex() })
    vim.api.nvim_set_hl(0, "@0base900", { fg = base_900:hex() })

    vim.api.nvim_set_hl(0, "@0red", { fg = red:hex() })
    vim.api.nvim_set_hl(0, "@0yellow", { fg = yellow:hex() })
    vim.api.nvim_set_hl(0, "@0blue", { fg = blue:hex() })
    vim.api.nvim_set_hl(0, "@0green", { fg = green:hex() })
    vim.api.nvim_set_hl(0, "@0orange", { fg = orange:hex() })
    vim.api.nvim_set_hl(0, "@0purple", { fg = purple:hex() })

    vim.api.nvim_set_hl(0, "@none", { fg = "", bg = "" })

    -- nvim
    -- ctermbg
    vim.api.nvim_set_hl(0, "Normal", { bg = transparent and "" or base_800:hex(), fg = text_200:hex() })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = transparent and "" or base_800:hex(), fg = text_200:hex() })
    vim.api.nvim_set_hl(0, "Visual", { bg = base_700:darken(15):hex() })
    vim.api.nvim_set_hl(0, "HighlightYank", { bg = base_700:hex() })
    vim.api.nvim_set_hl(0, "StatusLine", { bg = transparent and "" or base_800:hex() })
    vim.api.nvim_set_hl(0, "StatusLineNC", { bg = transparent and "" or base_800:hex() })
    vim.api.nvim_set_hl(0, "WinBar", { bg = transparent and "" or base_800:lighten(1):hex() })
    vim.api.nvim_set_hl(0, "WinBarNC", { link = "WinBar" })
    vim.api.nvim_set_hl(0, "Pmenu", { bg = transparent and "" or base_800:hex(), fg = frost_300:darken(15):hex() })
    vim.api.nvim_set_hl(0, "PmenuThumb", {})
    vim.api.nvim_set_hl(0, "FloatBorder", { fg = base_700:hex() })
    vim.api.nvim_set_hl(0, "BlinkCmpDocBorder", { fg = base_600:hex() })
    vim.api.nvim_set_hl(0, "BlinkCmpMenuBorder", { fg = base_600:hex() })
    vim.api.nvim_set_hl(0, "MiniIndentscopeSymbol", { fg = base_800:darken(5):hex() })
    vim.api.nvim_set_hl(0, "WinSeparator", { fg = base_800:darken(5):hex() })
    vim.api.nvim_set_hl(0, "Folded", { fg = base_800:darken(5):hex() })

    -- lsp links
    vim.api.nvim_set_hl(0, "Constant", { fg = purple:hex() })
    vim.api.nvim_set_hl(0, "Identifier", { fg = text_200:hex() })
    vim.api.nvim_set_hl(0, "Special", { fg = green:fade():hex() })
    vim.api.nvim_set_hl(0, "Type", { fg = yellow:darken():hex() })
    vim.api.nvim_set_hl(0, "String", { fg = green:hex() })
    vim.api.nvim_set_hl(0, "Function", { fg = frost_200:hex() })
    vim.api.nvim_set_hl(0, "Statement", { fg = text_200:hex() })
    vim.api.nvim_set_hl(0, "Keyword", { fg = orange:hex() })
    vim.api.nvim_set_hl(0, "Comment", { italic = true, fg = base_600:hex() })

    -- lsp warnings
    vim.api.nvim_set_hl(0, "DiagnosticUnnecessary", { fg = base_500:darken():hex() })
    vim.api.nvim_set_hl(0, "DiagnosticError", { fg = red:hex() })
    vim.api.nvim_set_hl(0, "DiagnosticHint", { fg = yellow:hex() })
    vim.api.nvim_set_hl(0, "DiagnosticUnderlineError", { fg = "", bg = "" })
    vim.api.nvim_set_hl(0, "DiagnosticUnderlineWarn", { fg = "", bg = "" })
    vim.api.nvim_set_hl(0, "DiagnosticUnderlineOk", { fg = "", bg = "" })
    vim.api.nvim_set_hl(0, "DiagnosticUnderlineHint", { fg = "", bg = "" })
    vim.api.nvim_set_hl(0, "DiagnosticUnderlineInfo", { fg = "", bg = "" })

    -- lsp semantics
    vim.api.nvim_set_hl(0, "@text", { fg = text_200:hex() })
    vim.api.nvim_set_hl(0, "@variable", { fg = text_200:fade(8):hex() })
    vim.api.nvim_set_hl(0, "@function", { fg = frost_300:hex() })
    vim.api.nvim_set_hl(0, "@property", { fg = frost_300:darken(8):hex() })

    -- lua
    vim.api.nvim_set_hl(0, "@lsp.type.method.lua", {})

    -- tsx
    vim.api.nvim_set_hl(0, "@tag", { link = "@variable" })
    vim.api.nvim_set_hl(0, "@tag.builtin.tsx", { fg = base_300:hex() })
    vim.api.nvim_set_hl(0, "@tag.attribute.tsx", { fg = base_400:hex() })

    -- ts

    -- rust

    -- golang
    vim.api.nvim_set_hl(0, "@variable.parameter.go", {})

    -- git
    vim.api.nvim_set_hl(0, "Changed", { fg = yellow:darken(15):hex() })
    vim.api.nvim_set_hl(0, "Removed", { fg = red:saturate(5):hex() })
    vim.api.nvim_set_hl(0, "Added", { fg = green:saturate(35):darken(30):hex() })
    vim.api.nvim_set_hl(0, "DiffChange", { link = "Comment" })
    vim.api.nvim_set_hl(0, "DiffText", { fg = orange:hex(), bg = yellow:darken(60):hex() })
    vim.api.nvim_set_hl(0, "DiffDelete", { fg = red:hex(), bg = red:fade(20):darken(50):hex() })
    vim.api.nvim_set_hl(0, "DiffAdd", { fg = green:hex(), bg = green:darken(44):hex() })

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
    vim.api.nvim_set_hl(0, "TodoBgTODO", { fg = base_900:hex(), bg = green:saturate(15):hex(), bold = true })
    vim.api.nvim_set_hl(0, "TodoFgTODO", { fg = green:hex() })
    vim.api.nvim_set_hl(0, "TodoSignTODO", { fg = green:hex() })
    vim.api.nvim_set_hl(0, "AIActionsHeader", { link = "@text" })
    vim.api.nvim_set_hl(0, "AIActionsInActiveContext", { link = "@comment" })
    vim.api.nvim_set_hl(0, "AIActionsActiveContext", { fg = orange:hex() })

    vim.api.nvim_set_hl(0, "HackedPortalNC", { fg = base_500:hex(), bg = base_900:hex() })
    vim.api.nvim_set_hl(0, "HackedPortal", { fg = base_900:hex(), bg = orange:hex() })
    vim.api.nvim_set_hl(0, "HackedPortalEdgeNC", { fg = base_900:hex() })
    vim.api.nvim_set_hl(0, "HackedPortalEdge", { fg = orange:hex() })

    vim.api.nvim_set_hl(0, "SnacksBackdrop", { bg = transparent and "" or base_900:hex() })

    vim.api.nvim_set_hl(0, "MiniStatuslineModeNormal", { fg = base_900:hex(), bg = frost_200:hex(), bold = true })
    vim.api.nvim_set_hl(0, "MiniStatuslineModeReplace", { fg = base_900:hex(), bg = red:hex(), bold = true })
    vim.api.nvim_set_hl(0, "MiniStatuslineModeVisual", { fg = base_900:hex(), bg = purple:hex(), bold = true })
    vim.api.nvim_set_hl(0, "MiniStatuslineModeInsert", { fg = base_900:hex(), bg = green:hex(), bold = true })
    vim.api.nvim_set_hl(0, "MiniStatuslineModeCommand", { fg = base_900:hex(), bg = orange:hex(), bold = true })
end

M.setup()

return M
