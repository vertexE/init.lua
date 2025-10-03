return {
    config = function()
        require("sidekick").setup()
        vim.keymap.set("n", "ga", function()
            require("sidekick").nes_jump_or_apply()
        end)
    end,
}
