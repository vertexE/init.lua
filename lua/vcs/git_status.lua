local M = {}

local splits = require("ui.splits")
local confirm = require("ui.confirm")
local floats = require("ui.floats")
local tbl = require("tbl")
local buf = require("buf")
local extmarks = require("ui.extmarks")

local common = require("vcs.git_common")
local open = require("vcs.git_open")

local default_opts = {
    hl = {
        icon = "MiniIconsPurple",
        branch = "@constant",
        commit_sha = "Comment",
        commit_msg = "@text",
        change_type = "Comment",
        file_path = "Text",
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

local refresh_tray_on_mini_cmd = function()
    vim.api.nvim_create_autocmd({ "User" }, {
        group = vim.api.nvim_create_augroup("user.git.tray.refresh", { clear = true }),
        pattern = "MiniGitCommandDone",
        once = true,
        callback = function()
            if state.bufnr ~= nil and state.winr ~= nil then
                M.status_tray()
            end
        end,
    })
end

local quick_close = function(bufnr)
    vim.keymap.set("n", "q", function()
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end, { desc = "close the buffer", buffer = bufnr })
end

local to_normal_modes = function()
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
end

local git_stage = function(paths)
    vim.system({
        "git",
        "add",
        unpack(paths),
    }):wait()
end

local git_restore = function(paths)
    vim.system({
        "git",
        "restore",
        "--staged",
        unpack(paths),
    }):wait()
end

local git_reset = function(path)
    vim.system({ "git", "checkout", "HEAD", "--", path }):wait()
end

local git_diff = function(file, is_staged)
    vim.fn.jobstart(is_staged and { "git", "diff", "--staged", file } or { "git", "diff", file }, { term = true })
    vim.cmd("startinsert")
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
--- @param _ integer
--- @param changes table<git.Change>
local draw_tray = function(bufnr, _, changes)
    local ns = vim.api.nvim_create_namespace("user.git.tray")
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
    -- group changes into unstaged, working, partial, staged
    local changes_by_stage = tbl.group_by_selector(changes, function(change)
        return change.stage
    end)

    local head_sha = common.head_commit()
    if #head_sha > 0 then
        head_sha = head_sha:sub(1, 7)
    end

    local remote_sha = common.remote_commit()
    if #remote_sha > 0 then
        remote_sha = remote_sha:sub(1, 7)
    end

    local v_lines = {} -- we will instead write the lines to the buffer and apply and hl_group on each word
    table.insert(v_lines, {})
    table.insert(v_lines, {
        { " ", default_opts.hl.icon },
        { head_sha, default_opts.hl.commit_sha },
        { " ", "Comment" },
        { common.head_branch_name(), default_opts.hl.branch },
        { " ", "Comment" },
        { #head_sha > 0 and common.commit_msg(head_sha) or "", default_opts.hl.commit_msg },
    })
    table.insert(v_lines, {
        { " ", "MiniIconsPurple" },
        { remote_sha, "Comment" },
        { " ", "Comment" },
        { common.remote_branch_name(), default_opts.hl.branch },
        { " ", "Comment" },
        { #remote_sha > 0 and common.commit_msg(remote_sha) or "", "@text" },
    })
    -- TODO: can combine these stats at some point
    local unstaged_stats = common.git_stats()
    local staged_stats = common.git_stats(true)
    table.insert(v_lines, {
        { #unstaged_stats > 0 and "(unstaged) " or "", "Comment" },
        { #unstaged_stats > 0 and unstaged_stats or "", "MiniIconsOrange" },
        { " ", "Comment" },
        { #staged_stats > 0 and "(staged) " or "", "Comment" },
        { #staged_stats > 0 and staged_stats or "", "MiniIconsGreen" },
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

    extmarks.write_vlines_as_content(bufnr, ns, v_lines)
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
            if #res.stderr > 0 then
                vim.notify(res.stderr, vim.log.levels.ERROR, {})
                return
            end

            local redraw = true
            local changes = #res.stdout > 0 and parse_git_status(res.stdout) or {}
            state.changes = changes
            if state.bufnr == nil and state.winr == nil then
                local bufnr, winr = splits.horizontal(nil, { enter = true, height = 0.66, wo = { number = false } })
                state.bufnr = bufnr
                state.winr = winr
                vim.wo[winr].winbar =
                    "%#StatuslineSeparatorLsp#   s stage 󰿟 u unstage 󰿟 x reset 󰿟 cc commit 󰿟 o open-remote 󰿟 ll log 󰿟 PP push-set-upstream 󰿟 Pp push 󰿟 pp pull %#StatusLineSeparator#"
                redraw = false

                vim.api.nvim_create_autocmd({ "BufWipeout", "BufDelete" }, {
                    buffer = bufnr,
                    callback = function()
                        state.bufnr = nil
                        state.winr = nil
                    end,
                })
            end

            draw_tray(state.bufnr, state.winr, changes)
            vim.b.minicursorword_disable = true
            if not redraw then
                vim.api.nvim_win_set_cursor(state.winr, { 7, 0 })

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
                    local bufnr = floats.center({ height = 0.80, width = 0.88 })
                    vim.fn.jobstart("git commit", { term = true })
                    vim.cmd("startinsert")
                    vim.api.nvim_create_autocmd("TermClose", {
                        once = true,
                        callback = function()
                            M.status_tray()
                            vim.api.nvim_buf_delete(bufnr, { force = true })
                        end,
                    })
                end, { desc = "", buffer = state.bufnr })

                vim.keymap.set("n", "PP", function()
                    vim.cmd(string.format("Git push -u origin %s", common.head_branch_name()))
                    refresh_tray_on_mini_cmd()
                end, { desc = "", buffer = state.bufnr })

                vim.keymap.set("n", "pp", function()
                    vim.cmd(string.format("Git pull origin %s", common.head_branch_name()))
                    refresh_tray_on_mini_cmd()
                end, { desc = "", buffer = state.bufnr })

                vim.keymap.set("n", "Pp", function()
                    vim.cmd(string.format("Git push origin %s", common.head_branch_name()))
                    refresh_tray_on_mini_cmd()
                end, { desc = "", buffer = state.bufnr })

                vim.keymap.set("n", "ll", function()
                    vim.cmd("Git log --pretty=oneline")
                    local bufnr = vim.api.nvim_get_current_buf()
                    vim.keymap.set("n", "<enter>", function()
                        require("mini.git").show_at_cursor()
                        quick_close(vim.api.nvim_get_current_buf())
                    end, { desc = "", buffer = bufnr })
                    quick_close(bufnr)
                end, { desc = "", buffer = state.bufnr })

                vim.keymap.set("n", "x", function()
                    local file_paths = last_words_of_lines(buf.active_selection_lines())
                    if file_paths ~= nil and #file_paths > 0 then
                        local file = file_paths[1]
                        confirm.open("Are you sure you want to reset " .. file .. "?", function(accepted)
                            if accepted then
                                git_reset(file)
                                M.status_tray()
                            end
                        end)
                    end
                end, { desc = "", buffer = state.bufnr })

                vim.keymap.set("n", "o", function()
                    open.remote_branch()
                end, { desc = "", buffer = state.bufnr })

                vim.keymap.set("n", "<enter>", function()
                    local file_paths = last_words_of_lines(buf.active_selection_lines())
                    if file_paths ~= nil and #file_paths > 0 then
                        vim.api.nvim_buf_delete(state.bufnr, { force = true })
                        vim.cmd(string.format("edit %s", file_paths[1]))
                    end
                end, { desc = "", buffer = state.bufnr })

                vim.keymap.set("n", "<tab>", function()
                    local open_term = vim.loop.hrtime()
                    local file_paths = last_words_of_lines(buf.active_selection_lines())
                    if file_paths ~= nil and #file_paths > 0 then
                        local is_staged = in_staged(state.bufnr)
                        local bufnr = floats.center({ height = 0.80, width = 0.88 })
                        git_diff(file_paths[1], is_staged)

                        vim.api.nvim_create_autocmd("TermClose", {
                            once = true,
                            callback = function()
                                local close_term = vim.loop.hrtime()
                                local diff = math.floor((close_term - open_term) / 1e6)
                                if diff > 250 then
                                    vim.api.nvim_buf_delete(bufnr, { force = true })
                                end
                            end,
                        })
                    end
                end, { desc = "", buffer = state.bufnr })
            elseif state.last_cl > 0 then
                local max = #vim.api.nvim_buf_get_lines(state.bufnr, 0, -1, false)
                vim.api.nvim_win_set_cursor(state.winr, { math.min(state.last_cl, max), 0 })
            end
        end)
    )
end

return M
