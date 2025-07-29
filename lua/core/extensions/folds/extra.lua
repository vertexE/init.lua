local M = {}

local editor = require("core.extensions.folds.editor")
local generate = require("core.extensions.folds.generate")

local OFFSET = 4

local find_diff_ranges = function()
    local diffs = require("mini.diff").export("qf", { scope = "current" })

    local ranges = {}
    for _, diff in pairs(diffs) do
        table.insert(ranges, { math.max(1, diff.lnum - OFFSET), diff.end_lnum + OFFSET })
    end

    return ranges
end

-- NOTE: no need for <tab>, we just use ]c instead

M.focus_diff = function()
    if vim.g.custom_focus_mode ~= nil and vim.g.custom_focus_mode then
        vim.cmd("normal zE")
        vim.g.custom_focus_mode = false
        editor.set_fold_options("user")
        return
    end
    editor.set_fold_options("manual")
    vim.cmd("normal zE")

    local diffs = find_diff_ranges()
    if #diffs == 0 then
        vim.notify("no diffs in current file", vim.log.levels.WARN, {})
        return
    end

    local folds = generate.folds_for_ranges(diffs)
    for _, fold in ipairs(folds) do
        vim.cmd(string.format("%d,%dfold", fold[1], fold[2]))
    end

    vim.g.custom_focus_mode = true
end

return M
