local M = {}

local store = require("ui.winbar.store")

--- @class winbar.filetype
--- @field ft string
--- @field icon string
--- @field hl string

--- @type table<winbar.filetype>
local file_type_decorations = {
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
        hl = "MiniIconsOrange",
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

--- @return table<table<string,string>>
local file_path = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local path = vim.fn.expand("%:.")
    local file = vim.fn.fnamemodify(path, ":t")
    local ext = vim.bo[bufnr].filetype
    if #file == 0 then
        return {}
    end
    --- @type winbar.filetype
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

    return {
        { "│ " or "", "Comment" },
        { ft_decoration.icon, ft_decoration.hl },
        { file, "@constant" },
        { vim.bo.modified and " ● " or "   ", "Comment" },
    }
end

M.setup = function()
    store.register_segment({
        name = "filepath",
        split = true,
        focused = function()
            return file_path()
        end,
        default = function()
            return file_path()
        end,
    })
end

return M
