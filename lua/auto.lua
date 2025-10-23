vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "COMMIT_EDITMSG",
    callback = function(ev)
        vim.keymap.set("n", "<enter>", function()
            vim.cmd("normal! ZZ")
        end, { buffer = ev.buf })
    end,
    desc = "save & close git commit",
})

vim.api.nvim_create_autocmd("RecordingEnter", {
    pattern = "*",
    callback = function()
        vim.cmd("redrawstatus")
    end,
    desc = "statusline",
})

vim.api.nvim_create_autocmd("RecordingLeave", {
    pattern = "*",
    callback = function()
        vim.cmd("redrawstatus")
    end,
    desc = "statusline",
})

vim.api.nvim_create_autocmd({ "ModeChanged" }, {
    pattern = "*",
    callback = function()
        vim.cmd("redrawstatus")
    end,
    desc = "statusline",
})

vim.api.nvim_create_autocmd({ "TextYankPost" }, {
    pattern = { "*" },
    callback = function()
        vim.hl.on_yank({ higroup = "HighlightYank" })
    end,
    desc = "Highlight yanked text",
})
