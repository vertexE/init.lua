--- @type PackSpec
local M = {
    event = "BufEnter",
    cmd = "CodeDiff",
    config = function()
        require("esmuellert/codediff.nvim").setup({
            highlights = {
                line_insert = "CodeDiffLineInsert",
                line_delete = "CodeDiffLineDelete",
                char_insert = "CodeDiffCharInsert",
                char_delete = "CodeDiffCharDelete",
            },
        })
    end,
}

return M
