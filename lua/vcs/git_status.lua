local M = {}

-- TODO: enhancement idea, add diff stats

local splits = require("ui.splits")
local floats = require("ui.floats")
local tbl = require("tbl")
local buf = require("buf")

local default_opts = {
    hl = {
        icon = "MiniIconsPurple",
        branch = "@constant",
        commit_sha = "Comment",
        commit_msg = "@text",
        change_type = "Comment",
        file_path = "@constant",
    },
}

--- @alias git.ChangeType "modified"|"renamed"|"added"|"deleted"|"conflict"
--- @alias git.Stage "staged"|"untracked"|"working"|"partial"

--- @class git.State
--- @field changes table<git.Change>
--- @field file_open string
--- @field lines_to_path table<integer,git.Change> line number in status buf mapping to git.Change
--- @field winr ?integer which window the status UI is open in
--- @field bufnr ?integer
--- @field last_cl integer

--- @class git.Change
--- @field file string
--- @field path string
--- @field stage git.Stage
--- @field type git.ChangeType
--- @field depth ?integer

--- @type git.State
local state = {
    changes = {},
    lines_to_path = {},
    file_open = "", -- which file (fullpath) to render the diff for
    winr = nil,
    bufnr = nil,
    last_cl = -1, -- last cursor position
}

local to_normal_modes = function()
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
end

local git_stage = function(paths)
    vim.fn.system({
        "git",
        "add",
        unpack(paths),
    })
end

local git_restore = function(paths)
    vim.fn.system({
        "git",
        "restore",
        "--staged",
        unpack(paths),
    })
end

local git_diff = function(file, staged)
    return vim.fn.system(staged and { "git", "diff", "--staged", file } or { "git", "diff", file })
end

local head_branch_name = function()
    local branch = vim.fn.system("git branch --show-current 2> /dev/null | tr -d '\n'")
    if branch ~= "" then
        return branch
    else
        return ""
    end
end

local remote_branch_name = function()
    local remote = vim.fn.system("git rev-parse --abbrev-ref --symbolic-full-name @{u} 2> /dev/null | tr -d '\n'")
    if remote ~= "" then
        return remote
    else
        return "no upstream"
    end
end

local head_commit = function()
    -- will show HEAD on a repo with no commits
    return vim.fn.system("git rev-parse HEAD 2> /dev/null | tr -d '\n'")
end

local remote_commit = function()
    return vim.fn.system("git rev-parse @{u} 2> /dev/null | tr -d '\n'") or "no upstream"
end

---@param commit_sha string
---@return string
local commit_msg = function(commit_sha)
    return vim.fn.system(string.format("git log -1 --pretty=%%s %s 2> /dev/null | tr -d '\n'", commit_sha))
end

---@param type git.ChangeType
---@return table<string>
local change_type_virtual = function(type)
    if type == "added" then
        return { " ", "MiniIconsGreen" }
    elseif type == "deleted" then
        return { " ", "MiniIconsRed" }
    elseif type == "modified" then
        return { " ", "MiniIconsOrange" }
    elseif type == "renamed" then
        return { " ", "Comment" }
    elseif type == "conflict" then
        return { " ", "MiniIconsRed" }
    end
    return { type, "Comment" }
end

---@param change git.Change
local change_to_vline = function(change)
    return {
        change_type_virtual(change.type),
        { " ", "Comment" },
        { change.path, default_opts.hl.file_path },
    }
end

--- draw the git status tray, update state.lines_to_path
--- this draw happen on every modification to the buffer
--- @param bufnr integer
--- @param winr integer
--- @param changes table<git.Change>
local draw_tray = function(bufnr, winr, changes)
    local ns = vim.api.nvim_create_namespace("user.git.tray")
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
    -- group changes into unstaged, working, partial, staged
    local changes_by_stage = tbl.group_by_selector(changes, function(change)
        return change.stage
    end)

    local head_sha = head_commit()
    if #head_sha > 0 then
        head_sha = head_sha:sub(1, 7)
    end

    local remote_sha = remote_commit()
    if #remote_sha > 0 then
        remote_sha = remote_sha:sub(1, 7)
    end

    local v_lines = {} -- we will instead write the lines to the buffer and apply and hl_group on each word
    table.insert(v_lines, {
        { "", "Comment" },
        { " git status ", "@text" },
        -- { "", "Comment" },
    })
    table.insert(v_lines, {
        { "Hint: ", "Comment" },
        { "s stage 󰿟 u unstage", "@constant" },
    })
    table.insert(v_lines, {}) -- blank line
    table.insert(v_lines, {
        { "  ", default_opts.hl.icon },
        { head_sha, default_opts.hl.commit_sha },
        { " ", "Comment" },
        { head_branch_name(), default_opts.hl.branch },
        { " ", "Comment" },
        { #head_sha > 0 and commit_msg(head_sha) or "", default_opts.hl.commit_msg },
    })
    table.insert(v_lines, {
        { "  ", "MiniIconsPurple" },
        { remote_sha, "Comment" },
        { " ", "Comment" },
        { remote_branch_name(), default_opts.hl.branch },
        { " ", "Comment" },
        { #remote_sha > 0 and commit_msg(remote_sha) or "", "@text" },
    })
    table.insert(v_lines, {}) -- blank line

    local untracked = changes_by_stage["untracked"] or {}
    if untracked and #untracked > 0 then
        table.insert(v_lines, {
            { string.format("Untracked (%s)", #untracked), "MiniIconsPurple" },
        })
        for _, change in ipairs(untracked) do
            table.insert(v_lines, change_to_vline(change))
        end
        table.insert(v_lines, {}) -- blank line
    end

    local partial = changes_by_stage["partial"] or {}
    local working_no_partial = changes_by_stage["working"] or {}
    local working = tbl.merge(working_no_partial, partial)
    if working and #working > 0 then
        table.insert(v_lines, {
            { string.format("Unstaged (%d)", #working), "MiniIconsPurple" },
        })
        for _, change in ipairs(working) do
            table.insert(v_lines, change_to_vline(change))
        end
        table.insert(v_lines, {}) -- blank line
    end

    local staged_no_partial = changes_by_stage["staged"] or {}
    local staged = tbl.merge(staged_no_partial, partial)
    if staged and #staged > 0 then
        table.insert(v_lines, {
            { string.format("Staged (%d)", #staged), "MiniIconsPurple" },
        })
        for _, change in ipairs(staged) do
            table.insert(v_lines, change_to_vline(change))
        end
    end

    if #untracked == 0 and #working == 0 and #staged == 0 then
        table.insert(v_lines, {
            { "no changes", "Comment" },
        })
    end

    local lines = {}
    for _, vline in ipairs(v_lines) do
        local line = ""
        for _, chunk in ipairs(vline) do
            line = line .. (chunk[1] or ""):gsub("[\r\n]", "")
        end
        table.insert(lines, line)
    end

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

    for linenr, vline in ipairs(v_lines) do
        local col = 0
        for _, chunk in ipairs(vline) do
            local text, hl_group = chunk[1], chunk[2]
            if text and #text > 0 and hl_group then
                -- Add extmark for this chunk
                vim.api.nvim_buf_set_extmark(bufnr, ns, linenr - 1, col, {
                    end_col = col + #text,
                    hl_group = hl_group,
                    -- Add other extmark options as needed
                })
                col = col + #text
            elseif text then
                col = col + #text
            end
        end
    end
end

--- parse the output of git status
--- @param s string
--- @return table<git.Change>
local parse_git_status = function(s)
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

--- checks if we're in the staged section
--- @param bufnr integer
--- @return boolean
local in_staged = function(bufnr)
    local cl = vim.fn.getpos(".")[2]
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    for i, line in ipairs(lines) do
        if line:match("Staged") then
            return i <= cl
        end
    end
    return false
end

--- get the last word on the current line
--- @param lines table<string>
--- @return table<string>
local last_words_of_lines = function(lines)
    return vim.iter(lines)
        :map(function(line)
            local words = vim.split(line, "%s+", { trimempty = true })
            if #words > 0 then
                local last_word_trimmed = words[#words]:gsub("%s+", "")
                return last_word_trimmed
            end
            return ""
        end)
        :filter(function(v)
            return #v > 0
        end)
        :totable()
end

M.status_tray = function()
    vim.system(
        { "git", "status", "--short" },
        { text = true },
        vim.schedule_wrap(function(res)
            local redraw = true
            if #res.stdout > 0 then
                local changes = parse_git_status(res.stdout)
                state.changes = changes
                if state.bufnr == nil and state.winr == nil then
                    local bufnr, winr = splits.horizontal(nil, { enter = true, height = 0.66, wo = { number = false } })
                    state.bufnr = bufnr
                    state.winr = winr
                    redraw = false

                    vim.api.nvim_create_autocmd({ "BufWipeout", "BufDelete" }, {
                        buffer = bufnr,
                        callback = function()
                            -- open a new win
                            state.bufnr = nil
                            state.winr = nil
                        end,
                    })
                end

                draw_tray(state.bufnr, state.winr, changes)
                vim.b.minicursorword_disable = true
                if not redraw then
                    vim.api.nvim_win_set_cursor(state.winr, { 6, 0 })

                    vim.keymap.set({ "n", "x" }, "s", function()
                        local file_paths = last_words_of_lines(buf.active_selection_lines())
                        if file_paths ~= nil and #file_paths > 0 then
                            git_stage(file_paths)
                            M.status_tray()
                            to_normal_modes()
                            state.last_cl = vim.fn.getpos(".")[2]
                        end
                    end, { desc = "", buffer = state.bufnr })

                    vim.keymap.set({ "n", "x" }, "u", function()
                        local file_paths = last_words_of_lines(buf.active_selection_lines())
                        if file_paths ~= nil and #file_paths > 0 then
                            git_restore(file_paths)
                            M.status_tray()
                            to_normal_modes()
                            state.last_cl = vim.fn.getpos(".")[2]
                        end
                    end, { desc = "", buffer = state.bufnr })

                    vim.keymap.set("n", "cc", function()
                        -- use mini.git for handling commits
                        vim.cmd("Git commit")
                    end)

                    vim.keymap.set("n", "<enter>", function()
                        local file_paths = last_words_of_lines(buf.active_selection_lines())
                        if file_paths ~= nil and #file_paths > 0 then
                            vim.api.nvim_buf_delete(state.bufnr, { force = true })
                            vim.cmd(string.format("edit %s", file_paths[1]))
                        end
                    end, { desc = "", buffer = state.bufnr })

                    vim.keymap.set("n", "<tab>", function()
                        -- FIXME: enahncement >> diffs need to use --staged option depending on where we are in the buffer
                        local file_paths = last_words_of_lines(buf.active_selection_lines())
                        if file_paths ~= nil and #file_paths > 0 then
                            local diff = git_diff(file_paths[1], in_staged(state.bufnr))
                            local bufnr = floats.center({ height = 0.80, width = 0.55, bo = { filetype = "diff" } })
                            vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(diff, "\n"))
                        end
                    end)
                elseif state.last_cl > 0 then
                    local max = #vim.api.nvim_buf_get_lines(state.bufnr, 0, -1, false)
                    vim.api.nvim_win_set_cursor(state.winr, { math.min(state.last_cl, max), 0 })
                end
            end
        end)
    )
end

return M
