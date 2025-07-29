local M = {}

local editor = require("core.extensions.folds.editor")
local user = require("core.extensions.folds.user")
local find = require("core.extensions.folds.find")
local generate = require("core.extensions.folds.generate")

-- local mini_notify = require("mini.notify")

M.user_ranges = function()
    if vim.g.custom_focus_mode ~= nil and vim.g.custom_focus_mode then
        vim.cmd("normal zE")
        vim.g.custom_focus_mode = false
        editor.set_fold_options("user")
        return
    end

    if #user.user_ranges == 0 then
        -- vim.notify("no set user ranges for this buffer", vim.log.levels.WARN, {})
        -- local id = mini_notify.add("no set user ranges for this buffer", "WARN", "Comment")
        -- vim.defer_fn(function()
        --     mini_notify.remove(id)
        -- end, 1500)
        return
    end

    editor.set_fold_options("manual")
    vim.cmd("normal zE")

    local folds = generate.folds_for_ranges(user.user_ranges)
    for _, fold in ipairs(folds) do
        vim.cmd(string.format("%d,%dfold", fold[1], fold[2]))
    end

    vim.notify("focused user ranges", vim.log.levels.INFO, {})
    vim.g.custom_focus_mode = true
end

--- @param text table<string>
M.text = function(text)
    if vim.g.custom_focus_mode ~= nil and vim.g.custom_focus_mode then
        vim.cmd("normal zE")
        vim.g.custom_focus_mode = false
        editor.set_fold_options("user")
        return
    end

    local matches = find.buffer_text(text)
    if #matches == 0 then
        vim.notify("no matches in buffer", vim.log.levels.WARN, {})
        return
    end

    editor.set_fold_options("manual")
    vim.cmd("normal zE")

    local folds = generate.folds_for_positions(matches)
    for _, fold in ipairs(folds) do
        vim.cmd(string.format("%d,%dfold", fold[1], fold[2]))
    end

    vim.notify("focused matches", vim.log.levels.INFO, {})
    vim.g.custom_focus_mode = true
end

--- @param words table<string>?
M.todos = function(words)
    words = words or { "TODO:", "NOTE:", "FIXME:", "BUG:" }
    return M.text(words)
end

M.marks = function()
    if vim.g.custom_focus_mode ~= nil and vim.g.custom_focus_mode then
        vim.cmd("normal zE")
        vim.g.custom_focus_mode = false
        editor.set_fold_options("user")
        return
    end

    local marks = find.find_marks()
    if #marks == 0 then
        vim.notify("no marks found, nowhere to focus", vim.log.levels.WARN, {})
        return
    end

    editor.set_fold_options("manual")
    vim.cmd("normal zE")

    local folds = generate.folds_for_positions(marks)
    for _, fold in ipairs(folds) do
        vim.cmd(string.format("%d,%dfold", fold[1], fold[2]))
    end

    vim.notify("focused marks", vim.log.levels.INFO, {})
    vim.g.custom_focus_mode = true
end

-- NOTE: if any intersection occurs between diagnostics, we leave them be
M.diagnostics = function()
    if vim.g.custom_focus_mode ~= nil and vim.g.custom_focus_mode then
        vim.cmd("normal zE")
        vim.g.custom_focus_mode = false
        editor.set_fold_options("user")

        vim.keymap.del("n", "<tab>")
        vim.keymap.del("n", "<s-tab>")
        return
    end

    vim.keymap.set("n", "<tab>", function()
        local diagnostic = vim.diagnostic.get_next()
        if diagnostic ~= nil then
            vim.api.nvim_win_set_cursor(0, { diagnostic.lnum, diagnostic.col })
        else
            vim.notify("no more diagnostics", vim.log.levels.INFO, {})
        end
    end, { desc = "go to next diagnostic" })

    vim.keymap.set("n", "<s-tab>", function()
        local diagnostic = vim.diagnostic.get_prev()
        if diagnostic ~= nil then
            vim.api.nvim_win_set_cursor(0, { diagnostic.lnum, diagnostic.col })
        else
            vim.notify("no more diagnostics", vim.log.levels.INFO, {})
        end
    end, { desc = "go to previous diagnostic" })

    local diagnostics = find.find_diagnostics()
    if #diagnostics == 0 then
        vim.notify("no diagnostics found, nowhere to focus", vim.log.levels.WARN, {})
        return
    end

    editor.set_fold_options("manual")
    vim.cmd("normal zE")

    local folds = generate.folds_for_positions(diagnostics)
    for _, fold in ipairs(folds) do
        vim.cmd(string.format("%d,%dfold", fold[1], fold[2]))
    end

    vim.notify("focused diagnostics", vim.log.levels.INFO, {})
    vim.g.custom_focus_mode = true
end

M.visual_selection = function()
    if vim.g.custom_focus_mode ~= nil and vim.g.custom_focus_mode then
        vim.cmd("normal zE")
        vim.g.custom_focus_mode = false
        editor.set_fold_options("user")
        return
    end

    local vs = find.visual_selection()
    if #vs == 0 then
        vim.notify("unable to get visual selection", vim.log.levels.WARN, {})
        return
    end

    editor.set_fold_options("manual")
    vim.cmd("normal zE")

    local folds = generate.folds_for_ranges(vs)
    for _, fold in ipairs(folds) do
        vim.cmd(string.format("%d,%dfold", fold[1], fold[2]))
    end

    vim.notify("focused visual selection", vim.log.levels.INFO, {})
    vim.g.custom_focus_mode = true
end

return M
