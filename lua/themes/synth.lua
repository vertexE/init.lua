local M = {}

local Color = require("color")

local config = {
    override_hl = function()
        return {}
    end,
    override_colors = {},
}

M.setup = function(c)
    config = vim.tbl_extend("force", config, c or {})

    vim.opt.termguicolors = true
    vim.opt.background = "dark"

    local color_defaults = {
        primary = "#00E6A8",
        surface = "#0D1118",
        text_100 = "#D7DCE5",
        text_200 = "#B8C0CC",
        text_300 = "#8E98A7",
        text_400 = "#687384",
        gray_500 = "#425064",
        gray_300 = "#52627A",
        gray_200 = "#73839B",
        gray_100 = "#9AA8BA",
        steel = "#2F3A4A",
        red = "#FF5C78",
        yellow = "#E6D84F",
        blue = "#4F83FF",
        green = "#00D787",
        orange = "#D98A2B",
        purple = "#B875FF",
        brown = "#B86B35",
        azure = "#4D7BFF",
        cyan = "#00D7E8",
    }

    local colors = {}
    for color, hex in pairs(color_defaults) do
        colors[color] = Color:from_hex(config.override_colors[color] or hex)
    end

    local defaults = {
        MiniIconsGrey = { fg = colors.steel:hex() },
        MiniIconsAzure = { fg = colors.azure:hex() },
        MiniIconsPurple = { fg = colors.purple:hex() },
        MiniIconsCyan = { fg = colors.cyan:hex() },
        MiniIconsRed = { fg = colors.red:hex() },
        MiniIconsGreen = { fg = colors.green:hex() },
        MiniIconsOrange = { fg = colors.orange:hex() },
        MiniIconsYellow = { fg = colors.yellow:hex() },
        MiniIconsBlue = { fg = colors.blue:hex() },

        Normal = { bg = colors.surface:darken(4):hex(), fg = colors.text_200:hex() },
        NormalFloat = { bg = colors.surface:hex(), fg = colors.text_200:hex() },
        Visual = { bg = colors.surface:lighten(10):hex() },
        HighlightYank = { bg = colors.gray_300:hex() },
        StatusLine = { bg = colors.surface:darken(4):hex() },
        StatusLineNC = { bg = colors.surface:darken(4):hex() },
        TabLineFill = { bg = colors.surface:darken(4):hex() },
        WinBar = { bg = colors.surface:lighten(1):hex() },
        WinBarNC = { link = "WinBar" },
        Pmenu = { bg = colors.surface:darken(4):hex(), fg = colors.text_300:hex() },
        PmenuThumb = {},
        FloatBorder = { fg = colors.steel:lighten(8):hex() },
        WinSeparator = { fg = colors.steel:darken(5):hex() },
        Folded = { fg = colors.gray_300:darken(5):hex() },
        FloatTitle = { fg = colors.red:hex(), italic = true },
        LineNr = { fg = colors.gray_500:darken(10):hex() },
        CursorLineNr = { fg = colors.gray_100:hex() },
        CursorLine = { bg = colors.surface:lighten(3):hex() },
        Comment = { italic = true, fg = colors.gray_500:hex() },
        CommentItalic = { italic = true, fg = colors.gray_500:hex() },
        CommentBg = { fg = colors.gray_100:hex(), bg = colors.surface:lighten(2):hex(), bold = true },
        Text = { fg = colors.text_200:hex() },
        TextDim = { fg = colors.text_400:hex() },
        TextDimmer = { fg = colors.gray_500:hex() },
        TextDimmest = { fg = colors.steel:darken(5):hex() },
        MsgArea = { link = "TextDim" },
        ModeMsg = { link = "TextDim" },
        OutlineGuides = { link = "TextDimmer" },
        OutlineFoldMarker = { link = "TextDimmer" },
        StatusLineSeparator = { fg = colors.steel:hex() },
        StatusLineSeparatorContent = { bg = colors.steel:hex(), fg = colors.text_400:hex() },
        StatuslineSeparatorLsp = { bg = colors.steel:hex(), fg = colors.gray_100:hex() },

        Constant = { fg = colors.gray_300:hex(), italic = true },
        Identifier = { fg = colors.green:hex() },
        Special = { fg = colors.gray_200:hex() },
        Type = { fg = colors.gray_300:hex(), italic = true },
        String = { fg = colors.gray_300:hex(), italic = true },
        Function = { fg = colors.primary:hex(), italic = true },
        Statement = { fg = colors.text_200:hex() },
        Keyword = { fg = colors.gray_500:hex(), italic = true },
        PmenuSel = { bg = colors.steel:lighten(7):hex(), fg = colors.text_100:hex(), bold = true },
        PmenuKind = { italic = true },
        BlinkCmpMenuBorder = { fg = colors.steel:hex() },
        BlinkCmpDocBorder = { fg = colors.steel:hex() },
        BlinkCmpMenuSelection = { bg = colors.steel:lighten(7):hex(), fg = colors.text_100:hex(), bold = true },
        CmpItemMenu = { fg = colors.text_400:hex() },

        LspInlayHint = { italic = true, fg = colors.gray_300:hex(), bg = colors.surface:lighten(2):hex() },
        LspCodeLens = { italic = true, fg = colors.gray_300:hex(), bg = colors.surface:lighten(2):hex() },
        CodeLensSeparator = { fg = colors.surface:lighten(6):hex() },
        CodeLensContentIcon = { fg = colors.primary:hex(), bg = colors.surface:lighten(6):hex() },
        CodeLensContent = { italic = true, fg = colors.gray_300:hex(), bg = colors.surface:lighten(6):hex() },

        DiagnosticUnnecessary = { fg = colors.steel:darken():hex() },
        DiagnosticError = { fg = colors.red:hex() },
        DiagnosticHint = { fg = colors.yellow:hex() },
        DiagnosticWarn = { fg = colors.orange:hex() },
        DiagnosticInfo = { fg = colors.cyan:darken(20):hex() },
        DiagnosticUnderlineError = { undercurl = true, sp = colors.red:hex() },
        DiagnosticUnderlineWarn = { undercurl = true, sp = colors.orange:hex() },
        DiagnosticUnderlineOk = { undercurl = true, sp = colors.green:hex() },
        DiagnosticUnderlineHint = { undercurl = true, sp = colors.yellow:hex() },
        DiagnosticUnderlineInfo = { undercurl = true, sp = colors.cyan:darken(20):hex() },
        DiagnosticInfoTextNoBg = { fg = colors.surface:hex() },
        DiagnosticInfoTextWithBg = { fg = colors.cyan:darken(20):hex(), bg = colors.surface:hex(), italic = true },
        DiagnosticErrorTextNoBg = { fg = colors.surface:hex() },
        DiagnosticErrorTextWithBg = { fg = colors.red:hex(), bg = colors.surface:hex(), italic = true },
        DiagnosticWarnTextNoBg = { fg = colors.surface:hex() },
        DiagnosticWarnTextWithBg = { fg = colors.orange:hex(), bg = colors.surface:hex(), italic = true },
        DiagnosticHintTextNoBg = { fg = colors.surface:hex() },
        DiagnosticHintTextWithBg = { fg = colors.yellow:hex(), bg = colors.surface:hex(), italic = true },
        DiagnosticErrorDotOnErrorBg = { fg = colors.red:hex(), bg = colors.surface:hex(), italic = true },
        DiagnosticWarnDotOnErrorBg = { fg = colors.orange:hex(), bg = colors.surface:hex(), italic = true },
        DiagnosticInfoDotOnErrorBg = { fg = colors.cyan:darken(20):hex(), bg = colors.surface:hex(), italic = true },
        DiagnosticHintDotOnErrorBg = { fg = colors.yellow:hex(), bg = colors.surface:hex(), italic = true },
        DiagnosticErrorDotOnWarnBg = { fg = colors.red:hex(), bg = colors.surface:hex(), italic = true },
        DiagnosticWarnDotOnWarnBg = { fg = colors.orange:hex(), bg = colors.surface:hex(), italic = true },
        DiagnosticInfoDotOnWarnBg = { fg = colors.cyan:darken(20):hex(), bg = colors.surface:hex(), italic = true },
        DiagnosticHintDotOnWarnBg = { fg = colors.yellow:hex(), bg = colors.surface:hex(), italic = true },
        DiagnosticErrorDotOnInfoBg = { fg = colors.red:hex(), bg = colors.surface:hex(), italic = true },
        DiagnosticWarnDotOnInfoBg = { fg = colors.orange:hex(), bg = colors.surface:hex(), italic = true },
        DiagnosticInfoDotOnInfoBg = { fg = colors.cyan:darken(20):hex(), bg = colors.surface:hex(), italic = true },
        DiagnosticHintDotOnInfoBg = { fg = colors.yellow:hex(), bg = colors.surface:hex(), italic = true },
        DiagnosticErrorDotOnHintBg = { fg = colors.red:hex(), bg = colors.surface:hex(), italic = true },
        DiagnosticWarnDotOnHintBg = { fg = colors.orange:hex(), bg = colors.surface:hex(), italic = true },
        DiagnosticInfoDotOnHintBg = { fg = colors.cyan:darken(20):hex(), bg = colors.surface:hex(), italic = true },
        DiagnosticHintDotOnHintBg = { fg = colors.yellow:hex(), bg = colors.surface:hex(), italic = true },
        StatusLineGreenTextNoBg = { link = "DiagnosticInfoTextNoBg" },
        StatusLineGreenTextWithBg = { link = "DiagnosticInfoTextWithBg" },
        StatusLineYellowTextNoBg = { link = "DiagnosticWarnTextNoBg" },
        StatusLineYellowTextWithBg = { link = "DiagnosticWarnTextWithBg" },
        StatusLineRedTextNoBg = { link = "DiagnosticErrorTextNoBg" },
        StatusLineRedTextWithBg = { link = "DiagnosticErrorTextWithBg" },

        ["@text"] = { fg = colors.text_200:hex() },
        ["@variable"] = { fg = colors.text_200:fade(8):hex() },
        ["@function"] = { link = "Function" },
        ["@string"] = { link = "String" },
        ["@string.escape"] = { fg = colors.yellow:darken(10):hex() },
        ["@string.special"] = { fg = colors.orange:hex() },
        ["@property"] = { fg = colors.gray_300:hex() },
        ["@lsp.type.method.lua"] = { fg = colors.primary:hex() },
        ["@lsp.type.property.lua"] = { fg = colors.gray_100:hex() },
        ["@lsp.type.string"] = { link = "String" },
        ["@tag.attribute.html"] = { fg = colors.steel:hex() },
        ["@tag.html"] = { fg = colors.gray_100:hex() },
        htmlTagName = { fg = colors.gray_100:hex() },
        ["@tag"] = { fg = colors.gray_100:hex() },
        ["@tag.tsx"] = { fg = colors.gray_100:hex() },
        ["@tag.builtin.tsx"] = { fg = colors.gray_100:hex() },
        ["@tag.attribute.tsx"] = { fg = colors.steel:hex() },
        ["@variable.parameter.go"] = {},
        ["@markup.strong"] = { fg = colors.red:hex(), bold = true },
        ["@markup.italic"] = { fg = colors.green:hex(), italic = true },
        ["@markup.heading.1.markdown"] = { fg = colors.orange:hex(), bold = true },
        gitcommitSummary = { fg = colors.brown:hex(), italic = true },

        Changed = { fg = colors.yellow:darken(15):fade(55):hex() },
        Removed = { fg = colors.red:darken(10):fade(44):hex() },
        Added = { fg = colors.green:fade(55):hex() },
        DiffChange = { link = "Comment" },
        DiffText = { fg = colors.orange:hex(), bg = colors.yellow:fade(12):darken(55):hex() },
        DiffDelete = { fg = colors.red:hex(), bg = colors.red:fade(66):darken(50):hex() },
        DiffAdd = { bg = colors.green:fade(33):darken(34):hex() },

        NeogitDiffDelete = { link = "DiffDelete" },
        NeogitDiffAdd = { link = "DiffAdd" },
        NeogitDiffDeleteHighlight = { link = "DiffDelete" },
        NeogitDiffAddHighlight = { link = "DiffAdd" },
        NeogitDiffContext = { link = "Normal" },
        NeogitDiffContextHighlight = { link = "Normal" },
        NeogitDiffHeader = { link = "Normal" },
        NeogitDiffContextCursor = { link = "Normal" },
        NeogitDiffDeleteCursor = { link = "DiffDelete" },
        NeogitDiffAddCursor = { link = "DiffAdd" },
        NeogitSectionHeader = { fg = colors.purple:hex() },
        NeogitStatusHEAD = { fg = colors.purple:hex() },

        TodoBgTODO = { fg = colors.steel:hex(), bg = colors.green:hex(), bold = true },
        TodoFgTODO = { fg = colors.green:hex() },
        TodoSignTODO = { fg = colors.green:hex() },
        SnacksBackdrop = { bg = colors.surface:hex() },

        MiniStatuslineModeNormal = {
            fg = colors.steel:darken(15):hex(),
            bg = colors.primary:fade(15):hex(),
            bold = true,
        },
        MiniStatuslineModeReplace = { fg = colors.steel:darken(15):hex(), bg = colors.red:hex(), bold = true },
        MiniStatuslineModeVisual = { fg = colors.steel:darken(15):hex(), bg = colors.purple:hex(), bold = true },
        MiniStatuslineModeInsert = { fg = colors.steel:darken(15):hex(), bg = colors.brown:hex(), bold = true },
        MiniStatuslineModeCommand = { fg = colors.steel:darken(15):hex(), bg = colors.orange:hex(), bold = true },
        MiniCompletionInfoBorderOutdated = { link = "FloatBorder" },
        MiniIndentscopeSymbol = { fg = colors.steel:darken(5):hex() },
        BlinkCmpKindFunction = { italic = true, fg = colors.purple:hex() },
        BlinkCmpKindMethod = { link = "BlinkCmpKindFunction" },
        BlinkCmpKindProperty = { italic = true, fg = colors.orange:hex() },
        BlinkCmpKindVariable = { italic = true, fg = colors.brown:hex() },
        BlinkCmpKindField = { italic = true, fg = colors.red:hex() },

        NormalMode = { fg = colors.primary:hex() },
        ReplaceMode = { fg = colors.red:hex() },
        CommandMode = { fg = colors.orange:hex() },
        PendingMode = { fg = colors.yellow:hex() },
        InsertMode = { fg = colors.brown:hex() },
        VisualMode = { fg = colors.purple:hex() },
    }

    local overrides = config.override_hl(colors)
    for hl, settings in pairs(overrides) do
        if defaults[hl] then
            defaults[hl] = vim.tbl_extend("force", defaults[hl], settings)
        else
            defaults[hl] = settings
        end
    end

    for group, opts in pairs(defaults) do
        vim.api.nvim_set_hl(0, group, opts)
    end
end

return M
