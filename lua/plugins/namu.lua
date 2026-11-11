--- @type PackSpec
local M = {
    config = function()
        require("namu").setup({
            namu_symbols = {
                enable = true,
                options = { icon = "󱙝 ", window = { title_prefix = "󱙝 " } },
            },
            colorscheme = { enable = false },
            ui_select = { enable = false },
        })
    end,
}

return M
