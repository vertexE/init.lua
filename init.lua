vim.g.mapleader = " "
vim.g.maplocalleader = ","
vim.g.hidden = true -- TODO: do I still need this?

local dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-mini/mini.nvim",
    "neovim/nvim-lspconfig",
    "williamboman/mason.nvim",
    "mason-org/mason-lspconfig.nvim",
    "folke/lazydev.nvim",
    "folke/snacks.nvim",
    "vertexE/synth.nvim",
    "stevearc/conform.nvim",
    "folke/noice.nvim",
    "MunifTanjim/nui.nvim",
    -- "folke/sidekick.nvim"
    -- "dap.nvim"
    -- "fold.nvim",
    -- "multibuffer"
    -- hacked.nvim temp, we pull this in slowly
}

local spec = {}
for _, dependency in ipairs(dependencies) do
    table.insert(spec, string.format("https://github.com/%s", dependency))
end

vim.pack.add(spec)

vim.cmd.colorscheme("synth")

require("settings")
require("keymaps")
require("auto")
require("lsp")

require("ui.statusline").setup()
require("ui.statusbar").setup()

-- load external
require("plugins")
