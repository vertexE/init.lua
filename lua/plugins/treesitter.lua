--- @type PackSpec
local M = {
    config = function()
        require("tree-sitter-manager").setup()
    end,
}

return M
