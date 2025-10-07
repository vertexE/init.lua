return {
    config = function()
        require("sidekick").setup()
        vim.keymap.set("n", "<enter>", function()
            require("sidekick").nes_jump_or_apply()
        end)

        require("CopilotChat").setup({
            mappings = {
                accept_diff = {
                    normal = "<C-CR>",
                    insert = "<C-CR>",
                },
                reset = {
                    normal = "<C-r>",
                    insert = "<C-r>",
                },
            },
        })
    end,
}
