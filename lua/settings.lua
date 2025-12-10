local symbols = require("symbols")

vim.filetype.add({
    extension = {
        http = "http",
        mdx = "mdx",
    },
})

vim.o.winborder = "rounded"

vim.opt.updatetime = 250

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.scrolloff = 3
vim.opt.signcolumn = "yes"

vim.opt.termguicolors = true

vim.o.showtabline = 0

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
vim.opt.fillchars = symbols.fold_chars()

vim.opt.swapfile = false
vim.opt.backup = false

vim.opt.inccommand = "split"

vim.opt.cursorline = false
vim.opt.guicursor = "n-v-c:block-Cursor/lCursor,i-ci:ver25-Cursor/lCursor"
vim.opt.mouse = "a"

vim.opt.undofile = true

vim.opt.exrc = true -- allow for .nvim.lua files per workspace

vim.g.c_syntax_for_h = 1 -- `.h` files are `c` instead of `cpp`

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

vim.opt.completeopt = "menuone,popup,noselect,noinsert,fuzzy" -- Customize completions -- and maybe noinsert?
vim.opt.pummaxwidth = 50

vim.opt.virtualedit = "block" -- Allow going past the end of line in visual block mode
vim.opt.formatoptions = "qjl1" -- Don't autoformat comments
vim.opt.splitkeep = "screen"

vim.go.shell = "/bin/bash"

vim.o.pumheight = 10
