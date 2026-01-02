vim.g.mapleader = " "
vim.g.maplocalleader = ","
vim.g.hidden = true -- TODO: do I still need this?

local pack = require("pack")

-- add venv to nvim python host prog
-- vim.g.python3_host_prog = vim.fn.stdpath("config") .. "/.venv/bin/python"

local dependencies = {
    { "dstein64/vim-startuptime" },
    -- common
    { "nvim-mini/mini.nvim", require("plugins.mini") },
    { "folke/snacks.nvim", require("plugins.snacks") },
    { "lewis6991/gitsigns.nvim", require("plugins.git") },

    -- lsp
    { "neovim/nvim-lspconfig", require("plugins.lsp") },
    { "williamboman/mason.nvim", { dependency = true } },
    { "mason-org/mason-lspconfig.nvim", { dependency = true } },
    { "folke/lazydev.nvim", { dependency = true } },
    { "stevearc/conform.nvim", { dependency = true } },
    { "saghen/blink.cmp", { dependency = true }, version = vim.version.range("1.*") },
    { "rafamadriz/friendly-snippets", { dependency = true } },
    { "mrcjkb/rustaceanvim", version = vim.version.range("^6") },
    { "hedyhli/outline.nvim", require("plugins.outline") },
    -- syntax & appearance
    { "nvim-treesitter/nvim-treesitter-textobjects", require("plugins.treesitter"), version = "main" },
    { "nvim-treesitter/nvim-treesitter", dependency = true, version = "main" },
    -- UI
    -- colorscheme
    { "catppuccin/nvim", require("plugins.colorscheme"), name = "catppuccin" },
    -- debugger
    { "rcarriga/nvim-dap-ui", require("plugins.dap") },
    { "nvim-neotest/nvim-nio", { dependency = true } },
    { "mfussenegger/nvim-dap", { dependency = true } },
    { "mfussenegger/nvim-dap-python", { dependency = true } },
    { "jbyuki/one-small-step-for-vimkind", { dependency = true } },
    -- other developer tools
    { "mistweaverco/kulala.nvim", require("plugins.kulala") },
    -- react support
    { "windwp/nvim-ts-autotag", require("plugins.react") },

    -- AI
    { "folke/sidekick.nvim", require("plugins.ai") },
    { "CopilotC-Nvim/CopilotChat.nvim", { dependency = true } },
    { "nvim-lua/plenary.nvim", { dependency = true } },
    -- personal plugins
    { "vertexE/fold.nvim", require("plugins.vertexe") },
    { "vertexE/multibuffer.nvim", { dependency = true } },
    { "vertexE/hacked.nvim", { dependency = true } },
}

local spec = {}
for _, dependency in ipairs(dependencies) do
    if type(dependency) == "table" then
        local src = dependency[1]
        local data = dependency[2]
        local version = dependency.version
        local name = dependency.name
        src = string.format("https://github.com/%s", src)
        table.insert(spec, {
            src = src,
            data = data,
            version = version,
            name = name,
        })
    else
        table.insert(spec, string.format("https://github.com/%s", dependency))
    end
end

pack.lazy_load(spec)

require("boot")
require("settings")
require("keymaps")
require("commands")
require("auto")
require("ui.statusline").setup()
require("ui.winbar").setup()

require("assistant").setup()
