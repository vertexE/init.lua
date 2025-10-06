return {
    config = function()
        require("lazydev").setup({
            library = {
                -- See the configuration section for more details
                -- Load luvit types when the `vim.uv` word is found
                { path = "${3rd}/luv/library", words = { "vim%.uv" } },
            },
        })

        require("blink.cmp").setup({
            -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
            keymap = { preset = "default" },
            appearance = {
                nerd_font_variant = "mono",
            },
            completion = { documentation = { auto_show = false } },
            signature = { enabled = true, window = { show_documentation = false } },
            sources = {
                default = { "lsp", "path", "snippets", "buffer" },
            },
            fuzzy = { implementation = "prefer_rust_with_warning" },
        })
    end,
}
