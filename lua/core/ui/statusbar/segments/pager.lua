local M = {}

local store = require("core.ui.statusbar.store")

--- @return table<table<string>>
local content = function()
    local active_tabpage = vim.api.nvim_tabpage_get_number(0)
    local total_tabpages = #vim.api.nvim_list_tabpages()
    if total_tabpages == 1 then
        return {}
    end
    return {
        { "(", "Comment" },
        { string.format("%d/%d", active_tabpage, total_tabpages), "@variable.builtin" },
        { ")", "Comment" },
    }
end

M.setup = function()
    store.register_segment({
        name = "pager",
        split = true,
        default = content,
        focused = content,
    })
end

return M
