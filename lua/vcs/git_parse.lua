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

--- @class git.Hunk
--- @field at integer 1-indexed line number from the - side of the @@ header
--- @field remove_count integer number of lines to delete
--- @field lines string[] replacement/inserted lines (empty = pure deletion)
--- @field extmark_id integer|nil tech-debt: owned by editor.stream for position tracking, not a parse concern

--- @class git.DiffFile
--- @field file string path relative to repo root (a/ prefix stripped)
--- @field changes git.Hunk[]
--- @field is_new boolean
--- @field is_deleted boolean

--- parse a unified diff string into a list of per-file changes
--- @param s string
--- @return git.DiffFile[]
M.parse_git_diff = function(s)
    local result = {}

    local current_file = nil --- @type git.DiffFile|nil
    local current_changes = nil --- @type git.Hunk[]|nil

    local op_at = nil --- @type integer|nil
    local op_remove = 0
    local op_lines = {}
    local line_pos = 1
    local in_hunk = false

    local function flush_op()
        if op_at ~= nil and (op_remove > 0 or #op_lines > 0) then
            table.insert(current_changes, {
                at = op_at,
                remove_count = op_remove,
                lines = op_lines,
                extmark_id = nil,
            })
        end
        op_at = nil
        op_remove = 0
        op_lines = {}
    end

    local function flush_file()
        if current_file ~= nil then
            flush_op()
            current_file.changes = current_changes
            table.insert(result, current_file)
        end
        current_file = nil
        current_changes = nil
        in_hunk = false
    end

    for line in s:gmatch("[^\r\n]+") do
        if line:sub(1, 10) == "diff --git" then
            flush_file()
            local bpath = line:match(" b/(.+)$")
            current_file = { file = bpath or "", changes = {}, is_new = false, is_deleted = false }
            current_changes = {}

        elseif line:sub(1, 8) == "new file" then
            if current_file then current_file.is_new = true end

        elseif line:sub(1, 12) == "deleted file" then
            if current_file then current_file.is_deleted = true end

        elseif line:sub(1, 13) == "--- /dev/null" then
            if current_file then current_file.is_new = true end

        elseif line:sub(1, 13) == "+++ /dev/null" then
            if current_file then current_file.is_deleted = true end

        elseif line:sub(1, 6) == "+++ b/" then
            if current_file then current_file.file = line:sub(7) end

        elseif line:sub(1, 2) == "@@" then
            flush_op()
            local minus_start = line:match("@@ %-(%d+)")
            line_pos = math.max(1, tonumber(minus_start) or 1)
            in_hunk = true

        elseif in_hunk and line:sub(1, 1) == "-" then
            if op_at == nil then
                op_at = line_pos
            end
            op_remove = op_remove + 1
            line_pos = line_pos + 1

        elseif in_hunk and line:sub(1, 1) == "+" then
            if op_at == nil then
                op_at = line_pos
            end
            table.insert(op_lines, line:sub(2))

        elseif in_hunk and line:sub(1, 1) == " " then
            flush_op()
            line_pos = line_pos + 1

        elseif in_hunk and line:sub(1, 1) == "\\" then
            -- "\ No newline at end of file" — skip
        end
    end

    flush_file()
    return result
end

return M
