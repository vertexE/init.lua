local M = {}

vim.api.nvim_create_autocmd("VimEnter", {
    group = vim.api.nvim_create_augroup("user.lazy.load", { clear = true }),
    callback = function()
        vim.defer_fn(function()
            require("plugins.snacks").config()
            require("plugins.dap").config()
            require("plugins.ai").config()
        end, 50)
    end,
})

vim.api.nvim_create_autocmd("BufEnter", {
    pattern = { "*.ts", "*.js", "*.html" },
    callback = function()
        require("plugins.react").config()
    end,
})

vim.api.nvim_create_autocmd("BufEnter", {
    pattern = { "*.http" },
    callback = function()
        require("plugins.kulala").config()
    end,
})

require("plugins.mini").config()
require("plugins.lsp").config()
require("plugins.vertexe").config()
require("plugins.noice").config()
require("plugins.treesitter").config()

return M
