local M = {}

M.setup = function()
    require("ui.statusbar.segments.filepath").setup()
    require("ui.statusbar.segments.git").setup()
    require("ui.statusbar.segments.pager").setup()
    require("ui.statusbar.segments.system").setup()
end

return M
