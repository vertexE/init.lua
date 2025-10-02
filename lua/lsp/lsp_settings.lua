local M = {}

M.copilot = {}

M.lua_ls = {
    Lua = {
        workspace = { checkThirdParty = false },
        telemetry = { enable = false },
        hint = {
            enable = true,
        },
    },
}

M.gopls = {
    gopls = {
        analyses = {
            unusedvariable = true,
        },
        hints = {
            assignVariableTypes = true,
            rangeVariableTypes = true,
            constantValues = true,
            parameterNames = true,
            functionTypeParameters = true,
        },
    },
}

M.yamlls = {
    yaml = {
        validate = false,
        format = {
            enable = true,
        },
        hover = true,
        completion = true,
    },
}

M.ts_ls = {
      typescript = {
        completions = {
            completeFunctionCalls = true,
        },
        referencesCodeLens = { enabled = true, showOnAllFunctions = false },
        inlayHints = {
            includeInlayParameterNameHints = "all",
            includeInlayParameterNameHintsWhenArgumentMatchesName = true,
            includeInlayFunctionParameterTypeHints = true,
            includeInlayVariableTypeHints = true,
            includeInlayVariableTypeHintsWhenTypeMatchesName = true,
            includeInlayPropertyDeclarationTypeHints = true,
            includeInlayFunctionLikeReturnTypeHints = true,
            includeInlayEnumMemberValueHints = true,
        },
    },
}

return M
