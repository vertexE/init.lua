--- @type PackSpec
local M = {
    event = "BufEnter",
    pattern = { "*.http" },
    config = function()
        require("kulala").setup()

        vim.keymap.set("n", "<leader>kr", function()
            require("kulala").run()
        end)

        vim.keymap.set("n", "<leader>kt", function()
            require("kulala").toggle_view()
        end)
    end,
}

return M
