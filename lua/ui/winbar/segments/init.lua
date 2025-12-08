local M = {}

M.setup = function()
    -- tabline
    require("ui.winbar.segments.project").setup()
    require("ui.winbar.segments.pager").setup()
    require("ui.winbar.segments.player").setup()
    require("ui.winbar.segments.git").setup()
    require("ui.winbar.segments.system").setup()
    -- winbar
    require("ui.winbar.segments.filepath").setup()
    -- I want some other stuff too....
end

return M
