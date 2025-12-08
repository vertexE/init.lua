local M = {}

local store = require("ui.winbar.store")

--- @return table<table<string>>
local content = function()
    local active_tabpage = vim.api.nvim_tabpage_get_number(0)
    local total_tabpages = #vim.api.nvim_list_tabpages()

    -- if total_tabpages == 1 then
    --     return {}
    -- end

    local lines = {}
    table.insert(lines, { " ", "StatuslineSeparatorLsp" })
    table.insert(lines, { "", "StatuslineSeparatorLsp" })

    for i = 1, total_tabpages, 1 do
        if i == active_tabpage then
            table.insert(lines, { " ", "StatuslineSeparatorLsp" })
            table.insert(lines, { "󱗝 ", "StatuslineSeparatorLsp" })
        else
            table.insert(lines, { " ", "StatuslineSeparatorLsp" })
            table.insert(lines, { "󰄱 ", "StatuslineSeparatorLsp" })
        end
    end

    table.insert(lines, { "", "StatusLineSeparator" })
    table.insert(lines, { " ", "Comment" })

    return lines
end

M.setup = function()
    store.register_segment({
        name = "pager",
        type = "tabline",
        split = false,
        content = content,
    })
end

return M
