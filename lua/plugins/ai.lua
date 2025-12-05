--- @type PackSpec
local M = {
    requires = {
        "plenary.nvim",
        "CopilotChat.nvim",
    },
    config = function()
        require("sidekick").setup({ nes = { enabled = false } })

        vim.keymap.set("n", "<leader>ac", function()
            require("sidekick.cli").toggle({ name = "claude", focus = true })
        end, { desc = "Sidekick Toggle Claude" })

        vim.keymap.set("x", "<leader>av", function()
            require("sidekick.cli").send({ msg = "{selection}" })
        end, { desc = "Send Visual Selection" })

        vim.keymap.set("n", "<leader>af", function()
            require("sidekick.cli").send({ msg = "{file}" })
        end, { desc = "Send File" })

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

return M
