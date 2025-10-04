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

        require("chat-context-ui").setup({
            ui = {
                layout = "split",
                split = "left",
            },
            agent = {
                callback = function(prompt, resolve)
                    require("CopilotChat").ask(prompt, {
                        headless = true,
                        callback = function(msg)
                            resolve(msg.content)
                        end,
                    })
                end,
            },
        })

        vim.keymap.set("n", "<localleader>ai", function()
            require("chat-context-ui").open()
        end, { desc = "open ai chat context ui" })
    end,
}
