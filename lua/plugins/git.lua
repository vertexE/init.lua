--- @type PackSpec
local M = {
    config = function()
        local gitsigns = require("gitsigns")
        gitsigns.setup({
            numhl = true,
        })

        vim.keymap.set("n", "<leader>hd", function()
            gitsigns.diffthis()
        end)

        vim.keymap.set("n", "<leader>hS", function()
            vim.system({ "git", "add", vim.fn.expand("%") })
            vim.notify("gitsigns: staged buffer!")
        end)

        vim.keymap.set("n", "<leader>hs", function()
            gitsigns.stage_hunk()
            vim.notify("gitsigns: staged hunk!")
        end)

        vim.keymap.set("v", "<leader>hs", function()
            gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
            vim.notify("gitsigns: staged hunk!")
        end)

        vim.keymap.set("n", "<leader>hi", gitsigns.preview_hunk_inline)

        vim.keymap.set("n", "<leader>hD", function()
            gitsigns.diffthis("~")
        end)

        vim.keymap.set("n", "]c", function()
            if vim.wo.diff then
                vim.cmd.normal({ "]c", bang = true })
            else
                gitsigns.nav_hunk("next")
            end
        end)

        vim.keymap.set("n", "[c", function()
            if vim.wo.diff then
                vim.cmd.normal({ "[c", bang = true })
            else
                gitsigns.nav_hunk("prev")
            end
        end)

        vim.keymap.set("n", "<leader>hr", function()
            gitsigns.reset_hunk()
            vim.notify("gitsigns: reset hunk!")
        end)
    end,
}

return M
