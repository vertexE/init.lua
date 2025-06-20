local M = {}

local lsp = function()
    vim.o.winborder = "rounded"
end

local custom_filetypes = function()
    vim.filetype.add({
        extension = {
            http = "http",
        },
    })
end

local plugin_globals = function()
    vim.g.copilot_no_tab_map = true
    -- disable copilot for buffer
    -- vim.b.copilot_enabled = false
end

local custom_globals = function()
    vim.g.work_dir = vim.env.HOME .. "/work"
    vim.g.tools_dir = vim.env.HOME .. "/tools"
    vim.g.notes_dir = vim.env.HOME .. "/notes"
    vim.g.learning_dir = vim.env.HOME .. "/learning"
end

local setup_neovide = function()
    vim.o.guifont = "GeistMono Nerd Font Mono"
    vim.g.neovide_transparency = 0.8
    vim.g.neovide_scale_factor = 1.2
    vim.g.neovide_theme = "auto"
end

local vim_globals = function()
    vim.g.mapleader = " "
    vim.g.maplocalleader = ","
    vim.g.hidden = true -- explicitly set to play nice with diffview
end

local statusline = function()
    -- vim.opt.laststatus = 2 -- Or 3 for global statusline
    -- vim.opt.statusline = " %f %m %= %l:%c ♥ "
    require("core.ui.statusline").setup()
end

M.setup = function()
    local ui = require("core.ui.style")
    statusline()
    custom_filetypes()
    vim_globals()
    plugin_globals()
    custom_globals()
    lsp()

    -- vim.opt.diffopt = "filler,in"

    -- reduce update time
    vim.opt.updatetime = 250

    vim.opt.tabstop = 4
    vim.opt.softtabstop = 4
    vim.opt.shiftwidth = 4
    vim.opt.expandtab = true

    vim.opt.scrolloff = 3
    vim.opt.signcolumn = "yes"

    vim.opt.termguicolors = true

    -- Show whitespace.
    -- vim.opt.list = true
    -- vim.opt.listchars = { space = '⋅', trail = '⋅', tab = '>-' }

    -- Folding.
    vim.o.foldcolumn = "0" -- set to display fold symbols
    vim.o.foldlevelstart = 99
    vim.o.foldmethod = "expr"
    vim.wo.foldtext = ""
    vim.opt.foldopen:remove("block")

    -- TODO: eventually this should be changed to nvim's builtin LSP
    -- see https://github.com/neovim/neovim/pull/31311
    vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"

    -- UI characters.
    vim.opt.fillchars = ui.fold_chars()

    vim.opt.swapfile = false
    vim.opt.backup = false

    vim.opt.inccommand = "split"

    -- can now use gy and gp
    -- vim.opt.clipboard = "unnamedplus"

    vim.opt.cursorline = false
    vim.opt.mouse = "a"

    vim.opt.undofile = true -- enable persistent undo

    vim.opt.exrc = true -- allow for .nvim.lua files per workspace

    vim.g.c_syntax_for_h = 1 -- `.h` files are `c` instead of `cpp`

    if vim.g.neovide then
        setup_neovide()
    end

    vim.opt.breakindent = true -- Indent wrapped lines to match line start
    -- vim.opt.cursorline    = true    -- Highlight current line
    vim.opt.linebreak = true -- Wrap long lines at 'breakat' (if 'wrap' is set)
    vim.opt.number = true -- Show line numbers
    vim.opt.relativenumber = false
    vim.opt.splitbelow = true -- Horizontal splits will be below
    vim.opt.splitright = true -- Vertical splits will be to the right

    vim.opt.ruler = false -- Don't show cursor position in command line
    vim.opt.showmode = false -- Don't show mode in command line
    vim.opt.wrap = false -- Display long lines as just one line

    vim.opt.signcolumn = "yes" -- Always show sign column (otherwise it will shift text)
    vim.opt.fillchars = "eob: " -- Don't show `~` outside of buffer

    -- Editing
    vim.opt.ignorecase = true -- Ignore case when searching (use `\C` to force not doing that)
    vim.opt.incsearch = true -- Show search results while typing
    vim.opt.infercase = true -- Infer letter cases for a richer built-in keyword completion
    vim.opt.smartcase = true -- Don't ignore case when searching if pattern has upper case
    vim.opt.smartindent = true -- Make indenting smart

    vim.opt.completeopt = "menuone,noinsert,noselect" -- Customize completions
    vim.opt.virtualedit = "block" -- Allow going past the end of line in visual block mode
    vim.opt.formatoptions = "qjl1" -- Don't autoformat comments
    vim.opt.splitkeep = "screen"
end

return M
