local M = {}

local tbl = require("tbl")
local buffer = require("buf")

--- @class git.blame.Parts
--- @field commit string
--- @field author string
--- @field date string
--- @field time string

--- @param blame string
--- @return git.blame.Parts
local parse_blame = function(blame)
    local commit = vim.split(blame, " ", { trimempty = true })[1]
    local author_datetime = vim.split(
        vim.split(blame, "(", { plain = true, trimempty = true })[2],
        ")",
        { plain = true, trimempty = true }
    )[1]
    local _start = string.find(author_datetime, "(%d+%-%d+%-%d+)")
    local author = string.sub(author_datetime, 1, _start - 1)
    local datetime = _start and string.sub(author_datetime, _start) or ""
    local datetime_parts = vim.split(datetime, " ", { trimempty = true })
    local date = #datetime_parts >= 2 and datetime_parts[1] or ""
    local time = #datetime_parts >= 2 and datetime_parts[2] or ""

    commit = string.gsub(commit, "%^", "") --- TODO: there may be more normalization changes I would need to do

    return {
        commit = commit,
        author = vim.trim(author),
        date = date,
        time = time,
    }
end

--- @param commit_sha string
--- @return string
local commit_message = function(commit_sha)
    local cmd = vim.system({ "git", "show", "-s", "--format=%B", commit_sha }, { text = true }):wait()
    if cmd.stdout then
        return vim.trim(cmd.stdout)
    end

    return ""
end

--- get the git blame for a line
local blame_win = -1
local blame_bufnr = -1

M.line = function()
    if vim.api.nvim_win_is_valid(blame_win) then
        vim.api.nvim_set_current_win(blame_win)
        vim.api.nvim_create_autocmd("WinLeave", {
            group = vim.api.nvim_create_augroup("git.blame.line", { clear = true }),
            once = true,
            callback = function()
                if vim.api.nvim_buf_is_valid(blame_bufnr) then
                    vim.api.nvim_buf_delete(blame_bufnr, { force = true })
                end
            end,
        })
        return
    end

    local rel_path = vim.fn.expand("%:.")
    local cur_pos = vim.fn.getpos(".")[2]
    blame_bufnr = vim.api.nvim_create_buf(false, true)
    local cmd = vim.system({ "git", "blame", rel_path, string.format("-L %d,%d", cur_pos, cur_pos) }, { text = true })
        :wait()
    local blame
    if #cmd.stderr > 0 then
        if string.find(cmd.stderr, "no such path") then
            blame = {
                author = "Untracked File",
                date = "now",
                time = "",
                commit = "00000000",
            }
        end
    elseif #cmd.stdout > 0 then
        blame = parse_blame(cmd.stdout)
    end

    local commit_symbol = ""
    blame_win = vim.api.nvim_open_win(blame_bufnr, false, {
        title = "git blame",
        border = "rounded",
        relative = "cursor",
        row = 0,
        col = 2,
        height = 3,
        width = 40,
    })
    vim.wo[blame_win].number = false

    vim.keymap.set("n", "<enter>", function()
        vim.system({ "gh", "browse", blame.commit }):wait()
    end, { buffer = blame_bufnr, desc = "git blame: browse commit" })

    vim.api.nvim_create_autocmd("CursorMoved", {
        group = vim.api.nvim_create_augroup("git.blame.line", { clear = true }),
        once = true,
        callback = function()
            if vim.api.nvim_buf_is_valid(blame_bufnr) then
                vim.api.nvim_buf_delete(blame_bufnr, { force = true })
            end
        end,
    })

    local message = commit_message(blame.commit)
    local ns_id = vim.api.nvim_create_namespace("git.blame.hover")
    vim.api.nvim_buf_set_extmark(blame_bufnr, ns_id, 0, 0, {
        virt_text = {
            { " ", "TodoFgTODO" },
            { blame.author .. " ", "TodoFgTODO" },
            { blame.date .. " " .. blame.time, "Comment" },
        },
        virt_lines = {
            { { message, "Comment" } },
            { { commit_symbol .. " " .. blame.commit, "TodoFgTODO" } },
        },
        virt_text_pos = "overlay",
    })
end

--- @param blame string
--- @return table<git.blame.Parts>
local parse_blame_lines = function(blame)
    local lines = vim.split(blame, "\n", { trimempty = true })
    local blames = {}
    for _, line in ipairs(lines) do
        local _blame = parse_blame(line)
        table.insert(blames, _blame)
    end
    return blames
end

--- display git blame for a selction in a split window
M.selection = function()
    if vim.api.nvim_win_is_valid(blame_win) then
        vim.api.nvim_set_current_win(blame_win)
    end

    local bufnr = vim.api.nvim_get_current_buf()
    local rel_path = vim.fn.expand("%:.")
    local sel_start, sel_end = buffer.active_selection()
    local cmd = vim.system({ "git", "blame", rel_path, string.format("-L %d,%d", sel_start, sel_end) }, { text = true })
        :wait()
    local blames
    if #cmd.stderr > 0 then
        if string.find(cmd.stderr, "no such path") then
            blames = tbl.rep({}, {
                author = "Untracked File",
                date = "now",
                time = "",
                commit = "00000000",
            }, sel_end - sel_start + 1)
        end
    elseif #cmd.stdout > 0 then
        blames = parse_blame_lines(cmd.stdout)
    end

    local blame_groups = tbl.group_by(blames, function(a, b)
        return a.commit == b.commit
    end)

    local ns = vim.api.nvim_create_namespace("git.blame.selection")
    vim.api.nvim_buf_clear_namespace(bufnr, ns, sel_start - 1, sel_end)
    local line = 1
    for i, blame_group in ipairs(blame_groups) do
        local hl = (i % 2) > 0 and "DiffAdd" or "DiffDelete"
        for j, blame in ipairs(blame_group) do
            if j == 1 then
                vim.api.nvim_buf_set_extmark(bufnr, ns, sel_start - 2 + line, 0, {
                    virt_text = {
                        { " ", hl },
                        { blame.author .. " ", hl },
                        { blame.date .. " " .. blame.time .. " ", hl },
                        { blame.commit, hl },
                    },
                    virt_text_pos = "right_align",
                    line_hl_group = hl,
                })
            else
                vim.api.nvim_buf_set_extmark(bufnr, ns, sel_start - 2 + line, 0, {
                    virt_text = {
                        { "│", hl },
                    },
                    virt_text_pos = "right_align",
                    line_hl_group = hl,
                })
            end
            line = line + 1
        end
    end

    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        group = vim.api.nvim_create_augroup("git.blame.selection", { clear = true }),
        buffer = bufnr,
        once = true,
        callback = function()
            vim.api.nvim_buf_clear_namespace(bufnr, ns, sel_start - 1, sel_end)
        end,
    })
end

M.browse_blame_commit = function()
    local rel_path = vim.fn.expand("%:.")
    local cur_pos = vim.fn.getpos(".")[2]
    local cmd = vim.system({ "git", "blame", rel_path, string.format("-L %d,%d", cur_pos, cur_pos) }, { text = true })
        :wait()
    local blame
    if #cmd.stderr > 0 then
        vim.notify("no commit found", vim.log.levels.WARN, {})
    elseif #cmd.stdout > 0 then
        blame = parse_blame(cmd.stdout)
        vim.system({ "gh", "browse", blame.commit }, { detach = true })
    end
end

return M
