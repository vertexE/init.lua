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

--- @param t table
--- @param comparator fun(a: any,b: any):boolean
M.group_by = function(t, comparator)
    local grouped = {}
    local group = {}
    for _, v in ipairs(t) do
        if #group > 0 and comparator(group[1], v) then -- if you belong in the current group
            table.insert(group, v)
        elseif #group > 0 then -- if you don't belong in the current group
            table.insert(grouped, group) -- insert the previous group
            group = { v } -- create a new group
        else -- base case where we have no current group
            table.insert(group, v)
        end
    end
    if #group > 0 then
        table.insert(grouped, group)
    end

    return grouped
end

--- @param t table<integer>
M.max = function(t)
    if #t == 0 then
        return 0
    end

    local m = t[1]
    for _, v in ipairs(t) do
        if v > m then
            m = v
        end
    end
    return m
end

--- take a slice of a table, returning
--- a new shallow copy of range given
--- @param t table table to copy from
--- @param i integer starting index (inclusive)
--- @param j integer ending index (inclusive)
--- @return table
M.slice = function(t, i, j)
    local _t = {}
    for k = i, j do
        table.insert(_t, t[k])
    end
    return _t
end

--- repeatedly add v to t n times
--- @param t table
--- @param v any
--- @param n integer
--- @return table
M.rep = function(t, v, n)
    local offset = #t
    for i = 1, n do
        t[i + offset] = v
    end
    return t
end

return M
