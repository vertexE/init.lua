local git = require("vcs.git_common")
local worktrees = require("assistant.worktrees")

local M = {}

local icon = function(status)
    if status == "done" then
        return ""
    elseif status == "failed" then
        return "󱋭"
    end

    return ""
end

local truncate = function(s)
    s = s:gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")
    if #s <= 64 then
        return s
    end

    return s:sub(1, 64) .. "..."
end

local preview = function(task)
    if task.patch then
        local file = io.open(task.patch, "r")
        if file then
            local content = file:read("*a")
            file:close()
            return content
        end
    end

    return string.format(
        "status: %s\nrequest: %s\nerror: %s",
        task.status,
        task.request,
        task.error or ""
    )
end

local finder = function()
    return vim.iter(worktrees.list())
        :map(function(task)
            return {
                text = string.format("%s %s", icon(task.status), truncate(task.request)),
                task = task,
                preview = { text = preview(task), ft = task.patch and "diff" or "text" },
            }
        end)
        :totable()
end

M.open = function()
    if #worktrees.list() == 0 then
        vim.notify("no worktree tasks found", vim.log.levels.INFO)
        return
    end

    require("snacks").picker.pick("worktree_tasks", {
        layout = { preset = "sidebar" },
        finder = finder,
        format = function(item)
            return { { item.text, "Title" } }
        end,
        preview = "preview",
        confirm = function(picker, item)
            picker:close()
            if not item or item.task.status ~= "done" or not item.task.patch then
                return
            end

            local ok, err = git.git_apply(item.task.patch)
            if ok then
                vim.notify("(assistant): applied worktree patch", vim.log.levels.INFO)
            else
                vim.notify(err, vim.log.levels.ERROR)
            end
        end,
    })
end

return M
