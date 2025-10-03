local M = {}

M.setup = function()
    require("ui.winbar.segments.filepath").setup()
    require("ui.winbar.segments.git").setup()
    require("ui.winbar.segments.pager").setup()
    require("ui.winbar.segments.system").setup()
end

return M
