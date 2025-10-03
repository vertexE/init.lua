return {
    config = function()
        require("hacked.blame").setup()
        require("hacked.executor").setup()
        require("hacked.portal").setup()
        require("hacked.buffers").setup()
        require("hacked.clipboard").setup()
        require("hacked.goto").setup()
        require("hacked.todo").setup()

        vim.keymap.set("n", "<leader>to", function()
            vim.cmd("e .nvim_todo.md")
        end, { desc = "open local todo" })

        vim.keymap.set("n", "<leader>tO", function()
            vim.cmd("e " .. vim.fn.expand("~/.nvim_todo.md"))
        end, { desc = "open root todo" })

        vim.keymap.set("n", "<c-f>", function()
            require("hacked.goto").menu()
        end, { desc = "open quick goto menu" })

        vim.keymap.set("n", "<leader>fa", function()
            require("hacked.goto").add()
        end, { desc = "add file to quick goto menu" })

        vim.keymap.set("n", "<c-1>", function()
            require("hacked.goto").quick_open(1)
        end, { desc = "quick goto file 1" })

        vim.keymap.set("n", "<c-2>", function()
            require("hacked.goto").quick_open(2)
        end, { desc = "quick goto file 2" })

        vim.keymap.set("n", "<c-3>", function()
            require("hacked.goto").quick_open(3)
        end, { desc = "quick goto file 3" })

        -- TODO: re-write this plugin!
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
        end, { desc = "save text blob to portal" })

        vim.keymap.set("n", "<leader>bo", function()
            require("hacked.portal").open()
        end, { desc = "open the portal" })

        vim.keymap.set("n", "<leader>bz", function()
            require("hacked.portal").clear()
        end, { desc = "clear the portal" })

        vim.keymap.set("n", "gb", function()
            require("hacked.blame").line()
        end, { desc = "git blame current line" })

        vim.keymap.set("v", "gb", function()
            require("hacked.blame").selection()
        end, { desc = "git blame lines" })

        vim.keymap.set("v", "<leader>go", function()
            -- TODO: if not visual- browse file?
            require("hacked.blame").browse()
        end, { desc = "open the current commit in the browser" })

        vim.keymap.set("n", "<leader>fe", function()
            require("multibuffer").lsp_diagnostics(0)
        end, { desc = "show lsp diagnostics in multibuffer" })

        vim.keymap.set("n", "<leader>fE", function()
            require("multibuffer").lsp_diagnostics()
        end, { desc = "show workspace diagnostics in multibuffer" })

        vim.keymap.set("n", "gR", function()
            require("multibuffer").lsp_references()
        end, { desc = "show lsp references in multibuffer" })

        vim.keymap.set("n", "<leader>fi", function()
            if require("fold").focused() then
                require("fold").text({})
                return
            end

            vim.ui.input({
                prompt = "Focus on buffer text",
            }, function(input)
                require("fold").text({ input })
            end)
        end, { desc = "narrow focus on text in buffer" })

        vim.keymap.set("n", "<leader>E", function()
            require("fold").diagnostics()
        end, { desc = "narrow focus on buffers lsp diagnostics" })

        vim.keymap.set("n", "<leader>M", function()
            require("fold").marks()
        end, { desc = "narrow focus on buffer local marks" })

        vim.keymap.set("x", "zz", function()
            require("fold").zen()
        end, { desc = "narrow focus onto selected region" })

        vim.keymap.set("n", "<leader>D", function()
            require("fold").diff()
        end, { desc = "narrow focus onto git diffs in current buffer" })
    end,
}
