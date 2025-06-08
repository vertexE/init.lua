# Neovim

### LSP + DAP setup

<img width="1512" alt="image" src="https://github.com/user-attachments/assets/67bd406a-0eb8-4cee-81ef-8e6e990dd85a" />
<img width="1512" alt="image" src="https://github.com/user-attachments/assets/213dd8b4-a013-49eb-b137-c93c2b069bd5" />

### Multibuffer
<img width="1512" alt="image" src="https://github.com/user-attachments/assets/01ac6c3a-c9e7-4792-991a-755f03df16ab" />

### Simple git-blame
<img width="1512" alt="Screenshot 2025-06-08 at 3 00 49 PM" src="https://github.com/user-attachments/assets/b3f12b0d-a64d-4d6a-b3ec-b6bb61a46b09" />


### Prerequisites

- install nvim, for macOS you can run `brew install neovim`
   
### Debugging

#### JS/TS

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

This setup requires `0.11.x` or above. During your first open,
Lazy (the package manager) will install itself if not found.
If you want to use dap, you will need the debugger tools, such as
- [debugpy for python](https://github.com/microsoft/debugpy)
- [codelldb for rust](https://github.com/mfussenegger/nvim-dap/wiki/C-C---Rust-(via--codelldb))

### What's Next

- steps extension
 - have a floating buffer where you can modify a "stack" of next steps
 - next step displayed in winbar
 - cycle steps via ] / [ 
 - complete a step as well
 - add / modify in the float (such as changing order)
 - since it's a stack, last added item on top
 - we'll overlay the text content
 - insert mode will wipe the ns 
 - back to normal, grab buffer content and update stack + draw again
 - dd will delete a step and we'll re-draw
- player
 - winbar of current music playing (uses CLI)
 - callback after song ends / prev / next / play

### Plugins
```
    ● catppuccin 3ms  start
    ● cmp-buffer 0.18ms  nvim-cmp
    ● cmp-nvim-lsp 0.16ms  nvim-cmp
    ● cmp-path 0.26ms  nvim-cmp
    ● cmp_luasnip 0.03ms  nvim-cmp
    ● copilot-chat-context.nvim 16.79ms  start
    ● copilot.vim 2.04ms  CopilotChat.nvim
    ● CopilotChat.nvim 11.23ms  copilot-chat-context.nvim
    ● fidget.nvim 2.39ms  nvim-lspconfig
    ● FixCursorHold.nvim 0.52ms  neotest
    ● flash.nvim 0.97ms  VeryLazy
    ● friendly-snippets 0.22ms  nvim-cmp
    ● gitsigns.nvim 1.56ms  statusbar.nvim
    ● grug-far.nvim 0.46ms  start
    ● hacked.nvim 1.05ms  start
    ● inline-session-notes.nvim 0.52ms  start
    ● kulala.nvim 2.91ms  start
    ● lazy.nvim 8.95ms  init.lua
    ● lazydev.nvim 0.4ms  nvim-lspconfig
    ● lspkind.nvim 0.2ms  nvim-cmp
    ● LuaSnip 2.72ms  nvim-cmp
    ● mason-lspconfig.nvim 0.04ms  nvim-lspconfig
    ● mason.nvim 1.87ms  nvim-lspconfig
    ● mini.nvim 4.29ms  copilot-chat-context.nvim
    ● minty 0.4ms  VeryLazy
    ● multibuffer.nvim 0.53ms  start
    ● namu.nvim 1.18ms  start
    ● neotest 16.44ms  VeryLazy
    ● neotest-go 0.31ms  neotest
    ● neotest-jest 0.25ms  neotest
    ● neotest-python 0.29ms  neotest
    ● noice.nvim 1.28ms  VeryLazy
    ● nui.nvim 0.23ms  noice.nvim
    ● nvim-cmp 4.78ms  nvim-lspconfig
    ● nvim-dap 0.39ms  nvim-dap-ui
    ● nvim-dap-go 0.22ms  nvim-dap-ui
    ● nvim-dap-python 0.23ms  nvim-dap-ui
    ● nvim-dap-ui 3.49ms  VeryLazy
    ● nvim-dap-virtual-text 0.25ms  nvim-dap-ui
    ● nvim-lint 0.08ms  VeryLazy
    ● nvim-lspconfig 73.79ms  start
    ● nvim-nio 0.25ms  neotest
    ● nvim-treesitter 5.68ms  start
    ● nvim-ts-autotag 1.13ms  start
    ● one-small-step-for-vimkind 0.23ms  nvim-dap-ui
    ● plenary.nvim 0.22ms  CopilotChat.nvim
    ● rustaceanvim 0.05ms  start
    ● snacks.nvim 0.56ms  start
    ● statusbar.nvim 2.44ms  start
    ● todo-comments.nvim 0.84ms  start
    ● vim-dadbod 0.24ms  start
    ● vim-dadbod-completion 0.13ms  start
    ● vim-dadbod-ui 0.4ms  start
    ● volt 0.25ms  minty
    ● conform.nvim  BufWritePre  ConformInfo  <leader>rr (v)  <leader>rr 
    ● vim-table-mode  md 

```

<img width="1510" alt="image" src="https://github.com/user-attachments/assets/83807a27-a186-41eb-84d5-a640d398fcb0" />
