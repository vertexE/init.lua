local M = {}

local store = require("ui.winbar.store")
local symbols = require("symbols")

--- @param focused boolean
--- @return table<table<string,string>>
local file_path = function(focused)
    local bufnr = vim.api.nvim_get_current_buf()
    local project = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
    local path = vim.fn.expand("%:.")
    local segments = vim.split(path, "/")
    local file = vim.fn.fnamemodify(path, ":t")
    if #file == 0 then
        return {}
    end

    local ft_decoration = symbols.file_icon(bufnr)

    local hl = focused and "@character" or "SnacksPickerPathHidden"
    local virtual_path = {
        { string.format(" %s", project), hl },
        { " 󰅂 ", hl },
    }

    for i, segment in ipairs(segments) do
        if i == #segments then
            table.insert(virtual_path, { ft_decoration.icon, focused and ft_decoration.hl or hl })
            table.insert(virtual_path, { string.format("%s", segment), focused and "@keyword" or hl })
            table.insert(virtual_path, { vim.bo.modified and " ● " or "   ", "MiniIconsOrange" })
        else
            table.insert(virtual_path, { string.format("%s", segment), hl })
            table.insert(virtual_path, { " 󰅂 ", hl })
        end
    end

    return virtual_path
end

M.setup = function()
    store.register_segment({
        name = "filepath",
        type = "winbar",
        split = true,
        content = function(focused)
            return file_path(focused)
        end,
    })
end

return M
