local M = {}

M.setup = function()
    require("core.ui.statusbar.segments.filepath").setup()
    require("core.ui.statusbar.segments.git").setup()
    require("core.ui.statusbar.segments.pager").setup()
    require("core.ui.statusbar.segments.system").setup()
end

return M
