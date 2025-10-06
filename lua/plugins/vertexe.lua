return {
    config = function()
        require("hacked.clipboard").setup()
        require("hacked.todo").setup()

        vim.keymap.set("n", "<leader>to", function()
            vim.cmd("e .nvim_todo.md")
        end, { desc = "open local todo" })

        vim.keymap.set("n", "<leader>tO", function()
            vim.cmd("e " .. vim.fn.expand("~/.nvim_todo.md"))
        end, { desc = "open root todo" })

        vim.keymap.set("n", "<leader>fe", function()
            require("multibuffer").lsp_diagnostics(0)
        end, { desc = "show lsp diagnostics in multibuffer" })

        vim.keymap.set("n", "<leader>fE", function()
            require("multibuffer").lsp_diagnostics()
        end, { desc = "show workspace diagnostics in multibuffer" })

        vim.keymap.set("n", "gr", function()
            require("multibuffer").lsp_references()
        end, { desc = "show lsp references in multibuffer" })

        vim.keymap.set("n", "gd", function()
            require("multibuffer").lsp_definitions(function(e)
                if string.match(e.fp, "react/index.d.ts") ~= nil then
                    return false
                end
                return true
            end)
        end, { desc = "show lsp definitions in multibuffer" })

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
