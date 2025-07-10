return {
    {
        -- dir = "/Users/jfdenton/work/multibuffer.nvim",
        "josiahdenton/multibuffer.nvim",
        config = function()
            vim.keymap.set("n", "<leader>fe", function()
                require("multibuffer").lsp_diagnostics()
            end)

            vim.keymap.set("n", "<leader>fm", function()
                require("multibuffer").marks()
            end)

            vim.keymap.set("n", "<leader>gr", function()
                require("multibuffer").lsp_references()
            end)
        end,
    },
}
