local set = vim.keymap.set
local opts = { noremap = true, silent = true }

local M = {}

local diff = require("core.extensions.diff")

local colors = function()
    set("n", "<localleader>i", function()
        local res = vim.api.nvim_exec2("Inspect", { output = true })
        local notify = require("mini.notify")
        notify.clear()
        local id = notify.add(res.output, "INFO", "Comment")
        vim.fn.setreg("*", res.output)
        vim.defer_fn(function()
            notify.remove(id)
        end, 30000)
    end, { desc = "inspect element hl-groups" })
end

local movement = function()
    set("n", "<c-y>", "<c-y><c-y><c-y>", { desc = "scroll up" })
    set("n", "<c-e>", "<c-e><c-e><c-e>", { desc = "scroll down" })
    set({ "n", "x" }, "j", [[v:count == 0 ? 'gj' : 'j']], { expr = true })
    set({ "n", "x" }, "k", [[v:count == 0 ? 'gk' : 'k']], { expr = true })
    set({ "n", "x" }, "H", "^")
    set({ "n", "x" }, "L", "$")
    set("n", "<C-u>", "8kzz", opts)
    set("n", "<C-d>", "8jzz", opts)
end

local editing = function()
    set("n", "<Esc>", "<CMD>nohlsearch<CR>")
    set("v", "<", "<gv")
    set("v", ">", ">gv")
    set("v", "J", ":m '>+1<CR>gv=gv", opts)
    set("v", "K", ":m '<-2<CR>gv=gv", opts)
    set({ "n", "x" }, "gy", '"+y', { desc = "Copy to system clipboard" })
    set("n", "gp", '"+p', { desc = "Paste from system clipboard" })
    -- - Paste in Visual with `P` to not copy selected text (`:h v_P`)
    set("x", "gp", '"+P', { desc = "Paste from system clipboard" })

    set({ "v", "x" }, "<leader><leader>", function()
        diff.selection_with_last_yank()
    end, { desc = "diff: selection with last yank" })
    -- local next_word_by_camel_case = function()
    --     -- TODO: figure out why this won't stop hi
    --     local parsed = vim.api.nvim_replace_termcodes("/\\u<cr><esc>", true, false, true)
    --     vim.api.nvim_feedkeys(parsed, "n", false)
    -- end
    -- set("n", "<localleader>w", next_word_by_camel_case, { desc = "go to next upper case word" })
end

local shortcuts = function()
    set("n", "<leader>mD", "delm ! | delm A-Z0-9", { desc = "clear all marks" })
    set({ "n", "x" }, ";", ":")
    set("n", "<leader>w", "<cmd>update<cr>", { desc = "save buffer" })
end

local windows = function()
    set({ "n" }, "<C-h>", "<C-w><C-h>", { desc = "move focus to left window" })
    set({ "n" }, "<C-l>", "<C-w><C-l>", { desc = "move focus to right window" })
    set({ "n" }, "<C-j>", "<C-w><C-j>", { desc = "move focus to lower window" })
    set({ "n" }, "<C-k>", "<C-w><C-k>", { desc = "move focus to upper window" })
    set({ "n" }, "<C-,>", "<C-w>5<")
    set({ "n" }, "<C-.>", "<C-w>5>")
    set({ "n" }, "<C-t>", "<C-w>+")
    set({ "n" }, "<C-s>", "<C-w>-")
end

local custom = function()
    -- local scratch = require("core.extensions.buffers")
    -- set("n", "<leader>tl", scratch.toggle_tasks_buffer, { desc = "open scratch markdown split" })
    set({ "n" }, "<leader>cp", function()
        local path = vim.fn.expand("%:.")
        vim.fn.setreg("*", path)
    end, { desc = "copy current buffer's relative file path" })

    set({ "n" }, "<leader>cpa", function()
        local path = vim.fn.expand("%:p")
        vim.fn.setreg("*", path)
    end, { desc = "copy current buffer's absolute file path" })

    -- simple zen mode
    -- TODO: fix zen with telescope buffers, may need to create auto command group?
    -- vim.g._zen_mode_active = false
    -- local prev_num_width = vim.o.numberwidth
    -- local toggle_zen_mode = function()
    --     if vim.g._zen_mode_active then
    --         vim.g._zen_mode_active = false
    --         vim.o.numberwidth = prev_num_width
    --     else
    --         vim.g._zen_mode_active = true
    --         vim.o.numberwidth = 20
    --     end
    -- end
    --
    -- set("n", "<leader>zz", toggle_zen_mode, { desc = "" })
end

local external = function()
    set("v", "gx", "<CMD>silent execute '!open ' .. shellescape(expand('<cfile>'), v:true)<CR>")
    set("t", "<c-/>", "<c-\\><c-n>")
end

M.setup = function()
    colors()
    movement()
    editing()
    shortcuts()
    windows()
    external()
    custom()
end

return M
