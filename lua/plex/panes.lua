local M = {}

function M.split_tab_name(name)
    local tag, title = name:match("^%[#([^%]]+)%] (.+)$")
    if not tag then
        return nil, name
    end
    return (tag:gsub("%%5D", "]"):gsub("%%25", "%%")), title
end

function M.tagged_name(name, tag)
    local _, title = M.split_tab_name(name)
    if tag then
        local escaped = tag:gsub("%%", "%%25"):gsub("%]", "%%5D")
        return "[#" .. escaped .. "] " .. title
    end
    return title
end

local function focus_rank(pane)
    if not pane.is_focused then
        return 0
    end
    return pane.is_floating and 2 or 1
end

function M.tabs(strategy, callback)
    strategy.panes(function(panes, err)
        if err then
            callback(nil, err)
            return
        end

        local by_tab = {}
        for _, pane in ipairs(panes) do
            local previous = by_tab[pane.tab_id]
            if not previous or focus_rank(pane) > focus_rank(previous) then
                by_tab[pane.tab_id] = pane
            end
        end

        local tabs = vim.tbl_values(by_tab)
        table.sort(tabs, function(a, b)
            return a.tab_position < b.tab_position
        end)
        callback(tabs)
    end)
end

return M
