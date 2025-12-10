local M = {}

local store = require("ui.winbar.store")

--- @class winbar.filetype
--- @field ft string
--- @field icon string
--- @field hl string

--- @type table<winbar.filetype>
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

--- @return table<table<string,string>>
local file_path = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local project = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
    local path = vim.fn.expand("%:.")
    local segments = vim.split(path, "/")
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

    local virtual_path = {
        { string.format(" %s", project), "DropBarIconUISeparator" },
        { "  ", "DropBarIconUISeparator" },
    }

    for i, segment in ipairs(segments) do
        if i == #segments then
            table.insert(virtual_path, { ft_decoration.icon, ft_decoration.hl })
            table.insert(virtual_path, { string.format("%s", segment), "Text" })
            table.insert(virtual_path, { vim.bo.modified and " ● " or "   ", "TextDim" })
        else
            table.insert(virtual_path, { string.format("%s", segment), "DropBarIconUISeparator" })
            table.insert(virtual_path, { "  ", "DropBarIconUISeparator" })
        end
    end

    return virtual_path
end

M.setup = function()
    store.register_segment({
        name = "filepath",
        type = "winbar",
        split = true,
        content = function()
            return file_path()
        end,
    })
end

return M
