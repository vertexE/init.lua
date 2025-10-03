local M = {}

vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    callback = function()
        require("plugins.snacks").config()
        require("plugins.dap").config()
        require("plugins.vertexe").config()
        require("plugins.ai").config()
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
require("plugins.noice").config()
require("plugins.treesitter").config()

vim.defer_fn(function()
    vim.cmd("doautocmd User VeryLazy")
end, 50)

return M
