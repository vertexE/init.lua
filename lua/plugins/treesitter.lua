local M = {
    config = function()
        require("nvim-treesitter").install({
            "lua",
            "rust",
            "python",
            "go",
            "c",
            "tsx",
            "html",
            "typescript",
            "javascript",
            "markdown",
            "markdown_inline",
            "vimdoc",
        })
    end,
}

return M
