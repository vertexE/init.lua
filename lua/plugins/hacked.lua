return {
    {
        "josiahdenton/hacked.nvim",
        -- dir = "/Users/jfdenton/work/hacked.nvim",
        dependencies = {
            "lewis6991/gitsigns.nvim",
        },
        config = function()
            require("hacked.blame").setup()
            require("hacked.executor").setup()
            require("hacked.portal").setup()
            require("hacked.buffers").setup()
            require("hacked.clipboard").setup()
            require("hacked.goto").setup()

            vim.keymap.set("n", "<c-f>", function()
                require("hacked.goto").menu()
            end)

            vim.keymap.set("n", "<leader>fa", function()
                require("hacked.goto").add()
            end)

            require("hacked.git").setup({
                actions = {
                    ["x"] = function(change, ctx) -- open compare
                        vim.api.nvim_set_current_win(ctx.prev_winr)
                        vim.cmd("edit " .. change.path)
                        if change.stage ~= "untracked" then
                            vim.defer_fn(function()
                                require("gitsigns").diffthis()
                            end, 500)
                        else
                            vim.notify("cannot diff untracked file", vim.log.levels.INFO, {})
                        end

                        return change
                    end,
                },
            })

            -- vim.keymap.set("n", "<leader>gg", function()
            --     require("hacked.git").status()
            -- end)

            -- vim.keymap.set({ "n" }, "<leader>M", function()
            --     -- TODO: wouldn't this make more sense as a floating win with shortcuts?
            --     require("hacked.buffers").open()
            -- end)

            vim.keymap.set({ "n", "x" }, "<leader>ba", function()
                require("hacked.portal").save()
            end)

            vim.keymap.set("n", "<leader>bo", function()
                require("hacked.portal").open()
            end)

            vim.keymap.set("n", "<leader>bz", function()
                require("hacked.portal").clear()
            end)

            vim.keymap.set("n", "gb", function()
                require("hacked.blame").line()
            end, { desc = "" })

            vim.keymap.set("v", "gb", function()
                require("hacked.blame").selection()
            end, { desc = "" })

            vim.keymap.set("v", "<leader>go", function()
                -- TODO: if not visual- browse file?
                require("hacked.blame").browse()
            end, { desc = "" })
        end,
    },
}
