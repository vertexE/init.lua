local M = {}

local store = require("ui.statusbar.store")

--- @return table<table<string>>
local content = function()
    local active_tabpage = vim.api.nvim_tabpage_get_number(0)
    local total_tabpages = #vim.api.nvim_list_tabpages()

    if total_tabpages == 1 then
        return {}
    end

    local lines = {}
    for i = 1, total_tabpages, 1 do
        if i == active_tabpage then
            table.insert(lines, { " ", "MiniIconsOrange" })
        else
            table.insert(lines, { " ", "MiniIconsOrange" })
        end

        table.insert(lines, { " ", "Comment" })
    end

    return lines
end

M.setup = function()
    store.register_segment({
        name = "pager",
        split = false,
        default = content,
        focused = content,
    })
end

return M
