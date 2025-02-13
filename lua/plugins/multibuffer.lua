return {
    {
        dir = "/Users/jfdenton/work/multibuffer.nvim",
        config = function()
            vim.keymap.set("n", "<leader>fe", function()
                require("multibuffer").lsp_diagnostics()
            end)

            vim.keymap.set("n", "<leader>gr", function()
                require("multibuffer").lsp_references()
            end)
        end,
    },
}
