return {
    {
        "folke/snacks.nvim",
        config = function()
            local snacks = require("snacks")
            snacks.setup({
                notifier = {},
                statuscolumn = {},
                picker = {
                    ui_select = true,
                },
                input = {},
                image = {},
            })

            vim.api.nvim_create_autocmd("User", {
                pattern = "MiniFilesActionRename",
                callback = function(event)
                    Snacks.rename.on_rename_file(event.data.from, event.data.to)
                end,
            })

            vim.keymap.set("n", "<leader>ff", function()
                snacks.picker.smart()
            end, { desc = "snacks: find files" })

            vim.keymap.set("n", "<leader>fp", function()
                snacks.picker.projects()
            end)

            vim.keymap.set("n", "<leader>fg", function()
                snacks.picker.grep({ layout = { preset = "sidebar" } })
            end, { desc = "snacks: find text" })

            vim.keymap.set("n", "<leader>fw", function()
                snacks.picker.grep_word({ layout = { preset = "sidebar" } })
            end, { desc = "snacks: find text" })

            vim.keymap.set("n", "<leader>fb", function()
                snacks.picker.buffers()
            end, { desc = "snacks: find buffer" })

            vim.keymap.set("n", "<leader>fn", function()
                snacks.picker.icons()
            end, { desc = "snacks: find icon" })

            vim.keymap.set("n", "<leader>fN", function()
                snacks.picker.notifications()
            end, { desc = "snacks: notification history" })

            vim.keymap.set("n", "<leader>hk", function()
                snacks.picker.keymaps({ layout = { preset = "sidebar" } })
            end, { desc = "snacks: find keymap" })

            vim.keymap.set("n", "<leader>cc", function()
                snacks.picker.colorschemes({ layout = { preset = "vscode" } })
            end, { desc = "snacks: colorscheme" })

            vim.keymap.set("n", "<leader>fh", function()
                snacks.picker.help()
            end, { desc = "snacks: help" })

            vim.keymap.set("n", "<localleader>ss", function()
                snacks.picker.spelling()
            end, { desc = "snacks: spelling" })

            vim.keymap.set("n", "<leader>gi", function()
                snacks.picker.git_log_file({ layout = { preset = "sidebar" } })
            end, { desc = "snacks: file history" })

            vim.keymap.set("n", "gr", function()
                snacks.picker.lsp_references({ layout = { preset = "sidebar" } })
            end, { desc = "snacks: references" })

            vim.keymap.set("n", "gd", function()
                snacks.picker.lsp_definitions({ layout = { preset = "sidebar" } })
            end, { desc = "snacks: definitions" })

            vim.keymap.set("n", "gD", function()
                snacks.picker.lsp_declarations({ layout = { preset = "sidebar" } })
            end, { desc = "snacks: declarations" })

            vim.keymap.set("n", "<leader>gb", function()
                snacks.picker.git_branches({ layout = { preset = "vscode" } })
            end, { desc = "snacks: git branches" })

            vim.keymap.set("n", "<leader>u", function()
                snacks.picker.undo({ layout = { preset = "sidebar" } })
            end)
        end,
    },
}
