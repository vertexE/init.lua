-- movement
vim.keymap.set("n", "<c-y>", "<c-y><c-y><c-y>", { desc = "scroll up" })
vim.keymap.set("n", "<c-e>", "<c-e><c-e><c-e>", { desc = "scroll down" })
vim.keymap.set({ "n", "x" }, "j", [[v:count == 0 ? 'gj' : 'j']], { expr = true })
vim.keymap.set({ "n", "x" }, "k", [[v:count == 0 ? 'gk' : 'k']], { expr = true })
vim.keymap.set({ "n", "x" }, "H", "^")
vim.keymap.set({ "n", "x" }, "L", "$")
vim.keymap.set("n", "<C-u>", "8kzz", { desc = "scroll up half", noremap = true, silent = true })
vim.keymap.set("n", "<C-d>", "8jzz", { desc = "scroll down half", noremap = true, silent = true })

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
