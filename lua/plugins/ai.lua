--- @type PackSpec
local M = {
    requires = {
        "plenary.nvim",
        "CopilotChat.nvim",
    },
    config = function()
        require("sidekick").setup({
            nes = { enabled = false },
            cli = {
                win = {
                    layout = "float",
                    float = {
                        width = 0.8,
                        height = 0.85,
                    },
                },
            },
        })

        vim.keymap.set({ "n", "x" }, "<leader>ac", function()
            require("sidekick.cli").toggle({ name = "codex", focus = true })
        end, { desc = "Sidekick Toggle Claude" })
    end,
}

return M
