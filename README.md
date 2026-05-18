# Neovim

Using a custom catppuccin theme with [Maple Mono](https://github.com/subframe7536/maple-font) font.

### Prerequisites

- install nvim, for macOS you can run `brew install neovim`
- ghostty theme [here](https://github.com/studio1804/ghostty-theme)
   
### Debugging

#### JS/TS

For node, install `js-debug-adapter`.

To use `pwa-chrome` and attach to a project, startup chrome 
in debug mode, such as 
```bash
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --remote-debugging-port=9222
```
Then you can attach to the running chrome session and put breakpoints in your code. 

#### Python

To debug python, dap-python comes with many defaults. To run
any module that imports relative, you must create an .nvim.lua file, e.g.
```lua
table.insert(require("dap").configurations.python, {
    type = "python",
    request = "launch",
    name = "Run Module",
    console = "integratedTerminal",
    module = "src.adapter.client", -- edit this to the module you are debugging
    cwd = "${workspaceFolder}",
    justMyCode = false,
})
```

### Setup

This setup requires `0.12.x` or above. Plugins are managed by `vim.pack`.
If you want to use dap, you will need debugger tools, such as
- [js-debug-adapter](https://github.com/microsoft/vscode-js-debug)
- [debugpy for python](https://github.com/microsoft/debugpy)
- [delve for golang](https://github.com/go-delve/delve)

### Plugins

```
-- multi-modules
nvim-mini/mini.nvim
folke/snacks.nvim

--- lsp
lewis6991/gitsigns.nvim
neovim/nvim-lspconfig
williamboman/mason.nvim
mason-org/mason-lspconfig.nvim
folke/lazydev.nvim
stevearc/conform.nvim
saghen/blink.cmp
rafamadriz/friendly-snippets
mrcjkb/rustaceanvim

--- support
hedyhli/outline.nvim
nvim-treesitter/nvim-treesitter-textobjects
nvim-treesitter/nvim-treesitter

--- colorscheme
catppuccin/nvim

--- debugger
rcarriga/nvim-dap-ui
nvim-neotest/nvim-nio
mfussenegger/nvim-dap
mfussenegger/nvim-dap-python
jbyuki/one-small-step-for-vimkind

--- dev tools/quality of life
mistweaverco/kulala.nvim
windwp/nvim-ts-autotag

--- AI
folke/sidekick.nvim
CopilotC-Nvim/CopilotChat.nvim
nvim-lua/plenary.nvim

--- personal
vertexE/fold.nvim
vertexE/multibuffer.nvim
vertexE/hacked.nvim
```

## Claude

### claude CLI hooks for statusline

Add the following to your `$HOME/.claude/settings.json`. This enables
statusline updates to inform the user of claude's status. If you have multiple
claude sessions running at once, this won't really work.

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "AskUserQuestion",
        "hooks": [
          {
            "type": "command",
            "command": "echo PROMPT > ~/.claude.status"
          }
        ]
      }
    ],
    "PermissionRequest": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "echo PROMPT > ~/.claude.status"
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "echo WORKING > ~/.claude.status"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "echo COMPLETE > ~/.claude.status"
          }
        ]
      }
    ]
  }
}
```
