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

-- NOTE: I could improve this by also rendering number of lsp errors / etc. in the file?? OR I do that on statusline

--- @return string
local file_path = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local path = vim.fn.expand("%:.")
    local file = vim.fn.fnamemodify(path, ":t")
    local ext = vim.bo[bufnr].filetype
    if #file == 0 then
        return ""
    end
    return (icons[ext] or "") .. file .. (vim.bo.modified and " ● " or "")
end

M.setup = function()
    store.register_segment({
        name = "filepath",
        split = true,
        focused = function()
            local file = file_path()
            return { { #file > 0 and "│ " or "", "Comment" }, { file, "@text" }, { "", "Comment" } }
        end,
        default = function()
            local file = file_path()
            return { { #file > 0 and "│ " or "", "Comment" }, { file, "@text" }, { "", "Comment" } }
        end,
    })
end

return M
