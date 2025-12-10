local M = {}

local store = require("ui.winbar.store")

--- @return table<table<string,string>>
local project = function()
    local dir = vim.fn.fnamemodify(vim.fn.getcwd(0, 0), ":t")

    return {
        { string.format("▌ %s ", dir), "NormalMode" },
    }
end

M.setup = function()
    store.register_segment({
        name = "project",
        type = "tabline",
        split = false,
        content = function()
            return project()
        end,
    })
end

return M
