local M = {}

--- @generic T
--- @param t table<T>
--- @param selector fun(v: T):string|number
--- @return table<string|number,table<T>>
M.group_by_selector = function(t, selector)
    local groups = {}
    for _, v in ipairs(t) do
        local sel_value = selector(v)
        local group = groups[sel_value] or {}
        table.insert(group, v)
        groups[sel_value] = group
    end

    return groups
end

--- merges two tables into a new table without modifying the originals
--- @generic T
--- @param t1 table<T>
--- @param t2 table<T>
--- @return table<T> t3 which is made from merging t1 and t2
M.merge = function(t1, t2)
    local t3 = { unpack(t1) }
    for _, entry in ipairs(t2) do
        t3[#t3 + 1] = entry
    end
    return t3
end

return M
