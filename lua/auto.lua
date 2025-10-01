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
        vim.highlight.on_yank({ higroup = "HighlightYank" })
    end,
    desc = "Highlight yanked text",
})
