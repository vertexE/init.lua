local buf = require("buf")

--- @type PackSpec
local M = {
    config = function()
        local gitsigns = require("gitsigns")
        gitsigns.setup({})

        vim.keymap.set("n", "<leader>hd", function()
            gitsigns.diffthis()
        end, { desc = "gitsigns: Diff this file" })

        vim.keymap.set("n", "<leader>hS", function()
            vim.system({ "git", "add", vim.fn.expand("%") })
            vim.notify("gitsigns: staged buffer!")
        end, { desc = "gitsigns: Stage buffer" })

        vim.keymap.set("n", "<leader>hs", function()
            gitsigns.stage_hunk()
            vim.notify("gitsigns: staged hunk!")
        end, { desc = "gitsigns: Stage hunk" })

        vim.keymap.set("v", "<leader>hs", function()
            gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
            vim.notify("gitsigns: staged hunk!")
        end, { desc = "gitsigns: Stage hunk (visual)" })

        vim.keymap.set("n", "<leader>hi", gitsigns.preview_hunk_inline, { desc = "gitsigns: Preview hunk inline" })

        vim.keymap.set("n", "<leader>hD", function()
            gitsigns.diffthis("~")
        end, { desc = "gitsigns: Diff against HEAD~" })

        vim.keymap.set("n", "]c", function()
            if vim.wo.diff then
                vim.cmd.normal({ "]c", bang = true })
            else
                gitsigns.nav_hunk("next")
            end
        end, { desc = "gitsigns: Next hunk/change" })

        vim.keymap.set("n", "[c", function()
            if vim.wo.diff then
                vim.cmd.normal({ "[c", bang = true })
            else
                gitsigns.nav_hunk("prev")
            end
        end, { desc = "gitsigns: Previous hunk/change" })

        vim.keymap.set("n", "<leader>hr", function()
            gitsigns.reset_hunk()
            vim.notify("gitsigns: reset hunk!")
        end, { desc = "gitsigns: Reset hunk" })

        vim.keymap.set("x", "<leader>hr", function()
            local sel_start, sel_end = buf.active_selection()
            gitsigns.reset_hunk({ sel_start, sel_end })
            vim.notify("gitsigns: reset hunk!")
        end, { desc = "gitsigns: Reset hunk" })
    end,
}

return M
