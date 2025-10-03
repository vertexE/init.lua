return {
    config = function()
        -- Setup is required, even if you don't pass any options
        require("kulala").setup()

        vim.keymap.set("n", "<leader>kr", function()
            require("kulala").run()
        end)

        vim.keymap.set("n", "<leader>kt", function()
            require("kulala").toggle_view()
        end)
    end,
}
