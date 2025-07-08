local M = {}

local store = require("core.ui.statusbar.store")

local icons = {
    lua = " ",
    python = "󰌠 ",
    typescriptreact = " ",
    javascriptreact = " ",
    json = " ",
    html = " ",
    css = " ",
    go = " ",
    rust = " ",
    typescript = "󰛦 ",
    javascript = " ",
}

--- @return string
local file_path = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local path = vim.fn.expand("%:.")
    local file = vim.fn.fnamemodify(path, ":t")
    local ext = vim.bo[bufnr].filetype
    if #file == 0 then
        return "󰏫 "
    end
    return (icons[ext] or "") .. file .. (vim.bo.modified and "  " or "")
end

M.setup = function()
    store.register_segment({
        name = "filepath",
        split = false,
        focused = function()
            return { { "", "StatusbarEdge" }, { file_path, "Statusbar" }, { "", "StatusbarEdge" } }
        end,
        default = function()
            return { { "", "StatusbarEdge" }, { file_path, "Statusbar" }, { "", "StatusbarEdge" } }
        end,
    })
end

return M
