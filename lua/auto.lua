local status = require("ui.status")

vim.api.nvim_create_autocmd("FileType", {
    pattern = {
        "lua",
        "rust",
        "python",
        "go",
        "c",
        "html",
        "typescript",
        "javascript",
        "typescriptreact",
        "javascriptreact",
        "markdown",
        "markdown_inline",
        "vimdoc",
    },
    callback = function()
        vim.treesitter.start()
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end,
})

vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "COMMIT_EDITMSG",
    callback = function(ev)
        vim.keymap.set("n", "<enter>", function()
            vim.cmd("normal! ZZ")
        end, { buffer = ev.buf })

        if status.is_open() then
            status.toggle_split()
        end
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
        vim.hl.hl_op({ higroup = "HighlightYank", timeout = 100 })
    end,
    desc = "Highlight yanked text",
})
