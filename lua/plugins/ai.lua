return {
    config = function()
        require("sidekick").setup()
        vim.keymap.set("n", "<s-enter>", function()
            require("sidekick").nes_jump_or_apply()
        end, { remap = true }) -- remap set to not override other <enter> callbacks

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
