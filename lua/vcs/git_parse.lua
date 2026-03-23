--- common git parsers
local M = {}

--- @class git.Change
--- @field file string
--- @field path string
--- @field stage git.Stage
--- @field type git.ChangeType
--- @field depth ?integer

--- parse the output of git status
--- @param s string
--- @return table<git.Change>
M.parse_git_status = function(s)
    local changes = {}
    for line in s:gmatch("[^\r\n]+") do
        local status = string.sub(line, 1, 2)
        local fp = string.sub(line, 3)
        fp = vim.trim(fp)

        -- handle rename case
        local _, last = fp:find(" -> ")
        if last ~= nil then
            fp = vim.trim(fp:sub(last))
        end

        local segments = vim.split(fp, "/")
        local file = segments[#segments]
        local stage_mark = string.sub(status, 1, 1)
        local unstaged = #vim.trim(string.sub(status, 2, 2)) > 0
        local staged = stage_mark ~= " " and stage_mark ~= "?" and stage_mark ~= "U"
        status = string.sub(vim.trim(status), 1, 1)
        local change = {
            file = file,
            path = fp,
            stage = status == "?" and "untracked"
                or ((unstaged and staged and "partial") or (staged and "staged" or "working")),
            type = (status == "M" or status == "m") and "modified"
                or status == "A" and "added"
                or status == "?" and "added"
                or status == "D" and "deleted"
                or status == "R" and "renamed"
                or "conflict",
        }
        table.insert(changes, change)
    end
    return changes
end

return M
