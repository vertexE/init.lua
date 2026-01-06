local M = {}

M.fold_chars = function()
    return {
        eob = " ",
        fold = ".",
        foldclose = "",
        foldopen = "",
        foldsep = " ",
        msgsep = "─",
    }
end

-- ├, ┤
M.rounded_border = function()
    return {
        { "╭", "FloatBorder" },
        { "─", "FloatBorder" },
        { "╮", "FloatBorder" },
        { "│", "FloatBorder" },
        { "╯", "FloatBorder" },
        { "─", "FloatBorder" },
        { "╰", "FloatBorder" },
        { "│", "FloatBorder" },
    }
end

local lsp_diagnostic_symbols = { Error = "", Warn = "", Hint = "", Info = "󰭺" }

local severity_to_word = {
    [vim.diagnostic.severity.ERROR] = "Error",
    [vim.diagnostic.severity.WARN] = "Warn",
    [vim.diagnostic.severity.INFO] = "Info",
    [vim.diagnostic.severity.HINT] = "Hint",
}

--- @param severity vim.diagnostic.Severity
--- @return string
M.severity_to_diagnostic_lvl = function(severity)
    local word = severity_to_word[severity]
    return lsp_diagnostic_symbols[word]
end

M.lsp_signs = function()
    return lsp_diagnostic_symbols
end

--- return a symbol representing the LSP server
--- @param name string
M.lsp_servers = function(name)
    if name:match("copilot") or name:match("Copilot") then
        return " "
    end
    if name:match("lua") then
        return " "
    end
    if name:match("angular") then
        return " "
    end
    if name:match("ts_ls") then
        return " "
    end
    if name:match("rust_analyzer") then
        return "󱘗 "
    end
    if name:match("tailwindcss") then
        return " "
    end
    if name:match("astro") then
        return " "
    end
    if name:match("gopls") then
        return " "
    end
    return ""
end

--- @class FileDecoration
--- @field ft string
--- @field icon string
--- @field hl string

--- @type table<FileDecoration>
local file_type_decorations = {
    {
        ft = "astro",
        icon = " ",
        hl = "MiniIconsRed",
    },
    {
        ft = "kitty",
        icon = " ",
        hl = "MiniIconsYellow",
    },
    {
        ft = "lua",
        icon = " ",
        hl = "MiniIconsAzure",
    },
    {
        ft = "python",
        icon = "󰌠 ",
        hl = "MiniIconsYellow",
    },
    {
        ft = "typescriptreact",
        icon = " ",
        hl = "MiniIconsBlue",
    },
    {
        ft = "javascriptreact",
        icon = " ",
        hl = "MiniIconsBlue",
    },
    {
        ft = "json",
        icon = " ",
        hl = "MiniIconsYellow",
    },
    {
        ft = "html",
        icon = " ",
        hl = "MiniIconsRed",
    },
    {
        ft = "css",
        icon = " ",
        hl = "MiniIconsBlue",
    },
    {
        ft = "go",
        icon = " ",
        hl = "MiniIconsCyan",
    },
    {
        ft = "rust",
        icon = " ",
        hl = "MiniIconsRed",
    },
    {
        ft = "typescript",
        icon = "󰛦 ",
        hl = "MiniIconsBlue",
    },
    {
        ft = "javascript",
        icon = " ",
        hl = "MiniIconsYellow",
    },
    {
        ft = "markdown",
        icon = " ",
        hl = "MiniIconsYellow",
    },
}

--- @param bufnr integer
--- @return FileDecoration
M.file_icon = function(bufnr)
    local ext = vim.bo[bufnr].filetype
    --- @type FileDecoration
    local ft_decoration = vim.iter(file_type_decorations):find(function(decoration)
        return decoration.ft == ext
    end)

    if not ft_decoration then
        ft_decoration = {
            ft = "unknown",
            icon = " ",
            hl = "MiniIconsGray",
        }
    end

    return ft_decoration
end

M.git = function()
    return {
        Branch = "",
    }
end

M.winbar = function()
    return {
        Folder = "󰉋",
        Separator = " ",
    }
end

return M
