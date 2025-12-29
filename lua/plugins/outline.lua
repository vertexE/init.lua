--- @type PackSpec
local M = {
    event = "VimEnter",
    config = function()
        require("outline").setup({
            position = "left",
            symbol_folding = {
                auto_unfold = {
                    only = 2,
                },
            },
            outline_items = {
                show_symbol_details = false,
            },
            preview_window = {
                auto_preview = true,
            },
        })
    end,
}

return M
