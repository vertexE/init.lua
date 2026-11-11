--- @type PackSpec
local M = {
    event = "BufEnter",
    cmd = "CodeDiff",
    config = function()
        require("codediff").setup({
            diff = {
                compact = true,
                compact_context_lines = 5,
            },
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
