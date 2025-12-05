--- @type PackSpec
local M = {
    event = "BufEnter",
    pattern = { "*.tsx", "*.html", "*.astro", "*.jsx", "*.md", "*.mdx" },
    config = function()
        require("nvim-ts-autotag").setup()
    end,
}

return M
