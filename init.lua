vim.g.mapleader = " "
vim.g.maplocalleader = ","
vim.g.hidden = true -- TODO: do I still need this?

local dependencies = {
    -- common
    "nvim-lua/plenary.nvim",
    "nvim-mini/mini.nvim",
    "folke/snacks.nvim",
    -- lsp config, server install
    "neovim/nvim-lspconfig",
    "williamboman/mason.nvim",
    "mason-org/mason-lspconfig.nvim",
    "folke/lazydev.nvim",
    -- syntax & appearance
    "nvim-treesitter/nvim-treesitter",
    "nvim-treesitter/nvim-treesitter-textobjects",
    "vertexE/synth.nvim",
    "folke/noice.nvim",
    "MunifTanjim/nui.nvim",
    -- debugger
    "rcarriga/nvim-dap-ui",
    "mfussenegger/nvim-dap",
    "mfussenegger/nvim-dap-python",
    "jbyuki/one-small-step-for-vimkind",
    "nvim-neotest/nvim-nio",
    -- other developer tools
    "stevearc/conform.nvim",
    "mistweaverco/kulala.nvim",
    -- react support
    "windwp/nvim-ts-autotag",
    -- AI
    "folke/sidekick.nvim",
    "CopilotC-Nvim/CopilotChat.nvim",
    "vertexE/chat-context-ui.nvim",
    -- personal plugins
    "vertexE/fold.nvim",
    "vertexE/multibuffer.nvim",
    "vertexE/hacked.nvim",
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
require("ui.winbar").setup()

-- load external
require("plugins")
