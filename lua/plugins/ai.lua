local splits = require("ui.splits")

return {
    config = function()
        require("sidekick").setup()
        vim.keymap.set("n", "ga", function()
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
        vim.keymap.set({ "n", "x" }, "<localleader>c", function()
            local _, winr = splits.vertical(nil, { enter = true, width = 50, split = "left" })
            require("CopilotChat").open({
                window = {
                    layout = "replace",
                },
            })

            local buf = vim.api.nvim_get_current_buf()
            vim.api.nvim_create_autocmd("BufLeave", {
                buffer = buf,
                once = true,
                callback = function()
                    if vim.api.nvim_win_is_valid(winr) then
                        vim.api.nvim_win_close(winr, true)
                    end
                end,
            })
        end)
    end,
}
