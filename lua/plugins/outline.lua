--- @type PackSpec
local M = {
    event = "VimEnter",
    config = function()
        require("outline").setup({
            position = "left",
            symbols = {
                filter = { "Function", "Method", "StaticMethod", "Class", "Enum", "Interface" },
            },
            symbol_folding = {
                auto_unfold = {
                    only = 2,
                },
            },
            outline_items = {
                auto_set_cursor = false,
                show_symbol_details = false,
            },
            outline_window = {
                show_cursorline = false,
            },
            preview_window = {
                auto_preview = false,
            },
            guides = {
                enabled = true,
                markers = {
                    bottom = "└",
                    middle = "├",
                    vertical = " ",
                },
            },
        })
    end,
}

return M
