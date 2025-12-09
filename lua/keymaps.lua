local git_tray = require("vcs.git_status")
local git_blame = require("vcs.git_blame")
local git_open = require("vcs.git_open")

local code_extract = require("treesitter.extract")

local status = require("ui.status")

local buf = require("buf")

-- movement
vim.keymap.set("n", "<c-y>", "<c-y><c-y><c-y>", { desc = "scroll up" })
vim.keymap.set("n", "<c-e>", "<c-e><c-e><c-e>", { desc = "scroll down" })
vim.keymap.set({ "n", "x" }, "j", [[v:count == 0 ? 'gj' : 'j']], { expr = true })
vim.keymap.set({ "n", "x" }, "k", [[v:count == 0 ? 'gk' : 'k']], { expr = true })
vim.keymap.set({ "n", "x" }, "H", "^")
vim.keymap.set({ "n", "x" }, "L", "$")
vim.keymap.set("n", "<C-u>", "8kzz", { desc = "scroll up half", noremap = true, silent = true })
vim.keymap.set("n", "<C-d>", "8jzz", { desc = "scroll down half", noremap = true, silent = true })
-- lsp uses c-m to jump back
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
vim.keymap.set("n", "<leader>q", "<cmd>cclose<cr>", { desc = "close quickfix window" })

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

vim.keymap.set("n", "<c-4>", function()
    require("navigation.goto").quick_open(4)
end, { desc = "quick goto file 4" })

vim.keymap.set({ "n", "x" }, "<localleader>g", function()
    require("assistant.llm").generate()
end, { desc = "llm: inline code generation" })

vim.keymap.set({ "n" }, "<localleader>a", function()
    require("assistant.resources").next_agent()
    vim.api.nvim_exec_autocmds("User", { pattern = "StatusRedraw" })
end, { desc = "llm: chang agent" })

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
    require("assistant.llm").ask()
end, { desc = "llm: ask agent a question" })

vim.api.nvim_create_user_command("Plan", function()
    require("assistant.llm").create_plan()
end, {})

vim.api.nvim_create_user_command("Review", function(cmd_args)
    local idx = tonumber(cmd_args.args)
    if not idx then
        vim.notify("(assistant): invalid cmd argument")
        return
    end
    require("assistant.llm").review_plan(idx)
end, { nargs = 1 })

vim.api.nvim_create_user_command("Execute", function(cmd_args)
    local idx = tonumber(cmd_args.args)
    if not idx then
        vim.notify("(assistant): invalid cmd argument")
        return
    end
    require("assistant.llm").execute_plan(idx)
end, { nargs = 1 })

vim.keymap.set("n", "<leader>o", function()
    status.toggle_split()
end)

vim.keymap.set("n", "<leader>sP", function()
    vim.system({ "sh", "-c", "echo pause > /tmp/fifoplayer-control" })
end, { desc = "spotify-player: pause track" })

vim.keymap.set("n", "<leader>sp", function()
    vim.system({ "sh", "-c", "echo play > /tmp/fifoplayer-control" })
end, { desc = "spotify-player: play track" })

vim.keymap.set("n", "<leader>sn", function()
    vim.system({ "sh", "-c", "echo next > /tmp/fifoplayer-control" })
end, { desc = "spotify-player: next track" })

vim.keymap.set({ "x", "n" }, "<leader>ex", function()
    local start_line, end_line = buf.active_selection()
    local content = code_extract.as_html(0, start_line - 1, end_line)
    vim.fn.setreg("*", content)
    vim.notify("copied code as html", vim.log.levels.INFO)
end)
