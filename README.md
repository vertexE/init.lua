# Neovim

Using [synth](https://github.com/vertexE/synth.nvim/tree/main) colorscheme and [Maple Mono](https://github.com/subframe7536/maple-font) font.

### lsp
<img width="1512" height="914" alt="image" src="https://github.com/user-attachments/assets/cb6fdfae-f0bc-4bb1-a7f9-4785d6a14e78" />

### dap
<img width="1512" height="904" alt="image" src="https://github.com/user-attachments/assets/ddf6ce5d-db87-48c7-a7e5-7b002ce5043e" />




### multibuffer - lsp references
<img width="1512" height="910" alt="image" src="https://github.com/user-attachments/assets/0da84ecb-7054-49a5-992f-a3936fb36f67" />

### multibuffer - lsp diagnostics
<img width="1512" height="914" alt="image" src="https://github.com/user-attachments/assets/094e70c2-62f2-4051-bd69-ce1503ee6438" />

### fold.nvim - find buffer text
<img width="1512" height="912" alt="image" src="https://github.com/user-attachments/assets/faba9dad-f060-4153-a711-15af699a3579" />


### git status tray
<img width="1511" height="912" alt="image" src="https://github.com/user-attachments/assets/49067451-6b2b-4de0-9ab7-d964bf3c05cb" />

### git diff (delta)
<img width="1512" height="911" alt="image" src="https://github.com/user-attachments/assets/a4a13005-51ec-48c6-bb19-0231b1113164" />


### Prerequisites

- install nvim, for macOS you can run `brew install neovim`
   
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
If you want to use dap, you will need the debugger tools, such as
- [js-debug-adapter](https://github.com/microsoft/vscode-js-debug)
- [debugpy for python](https://github.com/microsoft/debugpy)
- [delve for golang](https://github.com/go-delve/delve)

### Plugins

```lua
"nvim-mini/mini.nvim",
"folke/snacks.nvim",
-- lsp config, server install
"neovim/nvim-lspconfig",
"williamboman/mason.nvim",
"mason-org/mason-lspconfig.nvim",
"folke/lazydev.nvim",
-- appearance
"nvim-treesitter/nvim-treesitter",
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
-- personal plugins
"vertexE/fold.nvim",
"vertexE/multibuffer.nvim",
"vertexE/hacked.nvim",
```

