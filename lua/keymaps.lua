local git_tray = require("vcs.git_status")
local git_blame = require("vcs.git_blame")
local git_open = require("vcs.git_open")

local status = require("ui.status")

-- movement
vim.keymap.set("n", "<c-y>", "<c-y><c-y><c-y>", { desc = "scroll up" })
vim.keymap.set("n", "<c-e>", "<c-e><c-e><c-e>", { desc = "scroll down" })
vim.keymap.set({ "n", "x" }, "j", [[v:count == 0 ? 'gj' : 'j']], { expr = true })
vim.keymap.set({ "n", "x" }, "k", [[v:count == 0 ? 'gk' : 'k']], { expr = true })
vim.keymap.set({ "n", "x" }, "H", "^")
vim.keymap.set({ "n", "x" }, "L", "$")
vim.keymap.set("n", "<C-u>", "8kzz", { desc = "scroll up half", noremap = true, silent = true })
vim.keymap.set("n", "<C-d>", "8jzz", { desc = "scroll down half", noremap = true, silent = true })
-- lsp uses c-i to trigger completion
vim.keymap.set("n", "<c-m>", "<c-i>")

-- windows
vim.keymap.set({ "n" }, "<C-h>", "<C-w><C-h>", { desc = "move focus to left window" })
vim.keymap.set({ "n" }, "<C-l>", "<C-w><C-l>", { desc = "move focus to right window" })
vim.keymap.set({ "n" }, "<C-j>", "<C-w><C-j>", { desc = "move focus to lower window" })
vim.keymap.set({ "n" }, "<C-k>", "<C-w><C-k>", { desc = "move focus to upper window" })
vim.keymap.set({ "n" }, "<C-,>", "<C-w>5<")
vim.keymap.set({ "n" }, "<C-.>", "<C-w>5>")
vim.keymap.set({ "n" }, "<C-t>", "<C-w>+")
vim.keymap.set({ "n" }, "<C-s>", "<C-w>-")

-- editing
vim.keymap.set("n", "<Esc>", "<CMD>nohlsearch<CR>")
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { noremap = true, silent = true })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { noremap = true, silent = true })
vim.keymap.set({ "n", "x" }, "gy", '"+y', { desc = "Copy to system clipboard" })
vim.keymap.set("n", "gp", '"+p', { desc = "Paste from system clipboard" })

-- search
-- set({ "v", "x" }, "<leader><leader>", function()
--     diff.selection_with_last_yank()
-- end, { desc = "diff: selection with last yank" })

-- shortcuts
vim.keymap.set("n", "<leader>mD", "delm ! | delm A-Z0-9", { desc = "clear all marks" })
vim.keymap.set("n", "<leader>w", "<cmd>update<cr>", { desc = "save buffer" })

-- super commands
vim.keymap.set({ "n" }, "<leader>cp", function()
    local path = vim.fn.expand("%:.")
    vim.fn.setreg("*", path)
    vim.notify("copied relative filepath!", vim.log.levels.INFO, {})
end, { desc = "copy current buffer's relative file path" })

vim.keymap.set({ "n" }, "<leader>cpa", function()
    local path = vim.fn.expand("%:p")
    vim.fn.setreg("*", path)
    vim.notify("copied absolute filepath!", vim.log.levels.INFO, {})
end, { desc = "copy current buffer's absolute file path" })

vim.keymap.set("v", "gx", "<CMD>silent execute '!open ' .. shellescape(expand('<cfile>'), v:true)<CR>")
vim.keymap.set("t", "<c-/>", "<c-\\><c-n>")

-- git
vim.keymap.set("n", "<leader>gg", function()
    git_tray.status_tray()
end)

vim.keymap.set("n", "gb", function()
    git_blame.line()
end, { desc = "git blame current line" })

vim.keymap.set("v", "gb", function()
    git_blame.selection()
end, { desc = "git blame lines" })

vim.keymap.set("n", "<leader>go", function()
    git_blame.browse_blame_commit()
end, { desc = "open the current commit in the browser" })

vim.keymap.set("n", "<leader>gof", function()
    git_open.file()
end, { desc = "open the current file in the browser" })

-- navigation
vim.keymap.set("n", "<c-f>", function()
    require("navigation.goto").menu()
end, { desc = "open quick goto menu" })

vim.keymap.set("n", "<leader>fa", function()
    require("navigation.goto").add()
end, { desc = "add file to quick goto menu" })

vim.keymap.set("n", "<c-1>", function()
    require("navigation.goto").quick_open(1)
end, { desc = "quick goto file 1" })

vim.keymap.set("n", "<c-2>", function()
    require("navigation.goto").quick_open(2)
end, { desc = "quick goto file 2" })

vim.keymap.set("n", "<c-3>", function()
    require("navigation.goto").quick_open(3)
end, { desc = "quick goto file 3" })

vim.keymap.set({ "n", "x" }, "<localleader>g", function()
    require("assistant.copilot").generate()
end, { desc = "" })

vim.keymap.set("n", "<localleader><localleader>s", function()
    require("assistant.resources").toggle("selection")
    vim.api.nvim_exec_autocmds("User", { pattern = "StatusRedraw" })
end, { desc = "" })

vim.keymap.set("n", "<localleader><localleader>l", function()
    require("assistant.resources").toggle("lsp_diagnostics")
    vim.api.nvim_exec_autocmds("User", { pattern = "StatusRedraw" })
end, { desc = "" })

vim.keymap.set("n", "<localleader><localleader>g", function()
    require("assistant.resources").toggle("git_diff")
    vim.api.nvim_exec_autocmds("User", { pattern = "StatusRedraw" })
end, { desc = "" })

vim.keymap.set("n", "<localleader><localleader>b", function()
    require("assistant.resources").toggle("blocks")
    vim.api.nvim_exec_autocmds("User", { pattern = "StatusRedraw" })
end, { desc = "" })

vim.keymap.set("x", "<localleader>b", function()
    require("assistant.resources").add_block()
    vim.api.nvim_command('normal! "+y')
    vim.api.nvim_exec_autocmds("User", { pattern = "StatusRedraw" })
end, { desc = "" })

vim.keymap.set("n", "<localleader>z", function()
    require("assistant.resources").clear_blocks()
    vim.api.nvim_exec_autocmds("User", { pattern = "StatusRedraw" })
end, { desc = "" })

vim.keymap.set("n", "<localleader><localleader>f", function()
    require("assistant.resources").toggle("buffers")
    vim.api.nvim_exec_autocmds("User", { pattern = "StatusRedraw" })
end, { desc = "" })

vim.keymap.set({ "n", "x" }, "<localleader>o", function()
    require("assistant.resources").select_buffers()
    vim.api.nvim_exec_autocmds("User", { pattern = "StatusRedraw" })
end, { desc = "" })

vim.keymap.set({ "n", "x" }, "<localleader>c", function()
    require("assistant.copilot").ask()
end, { desc = "" })

vim.keymap.set("n", "<leader>o", function()
    status.toggle_split()
end)

-- --- improve winclose behavior with my goto shortcuts
-- vim.keymap.set("n", "ZQ", function()
--     if status.is_open() and vim.fn.winnr("$") == 2 then
--         status.toggle_split()
--         vim.cmd("q!")
--     elseif vim.fn.winnr("$") > 2 then
--         -- close then move to the previous win we were in
--         -- this stops the behavior of moving the cursor left
--         vim.cmd("q!")
--         -- we also refresh win width for status tray
--         -- by closing then re-opening
--         status.toggle_split()
--         vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<c-w>p", true, false, true), "n", false)
--         status.toggle_split()
--     else
--         vim.cmd("q!")
--     end
-- end, { desc = "quit without saving" })
--
-- vim.keymap.set("n", "ZZ", function()
--     if status.is_open() and vim.fn.winnr("$") == 2 then
--         status.toggle_split()
--         vim.cmd("x")
--     elseif status.is_open() and vim.fn.winnr("$") > 2 then
--         vim.cmd("x")
--         -- refresh win width for status tray
--         -- by closing then re-opening
--         status.toggle_split()
--         vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<c-w>p", true, false, true), "n", false)
--         status.toggle_split()
--     else
--         vim.cmd("x")
--     end
-- end, { desc = "save and quit" })
