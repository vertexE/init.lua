local M = {}

M.setup = function()
    local focus = require("core.extensions.folds.focus")

    vim.api.nvim_create_user_command("FocusDiagnostics", focus.diagnostics, {})

    vim.keymap.set("n", "<leader>E", focus.diagnostics, { desc = "focus diagnostics" })

    vim.api.nvim_create_user_command("FocusMarks", focus.marks, {})

    vim.keymap.set("n", "<leader>M", focus.marks, { desc = "focus marks" })

    vim.api.nvim_create_user_command("FocusVisualSelection", focus.visual_selection, {})
    vim.keymap.set({ "n", "v", "x" }, "<leader>v", focus.visual_selection, { desc = "focus visual selection" })

    local user = require("core.extensions.folds.user")
    vim.keymap.set(
        { "v", "x" },
        "<localleader>va",
        user.add_user_range,
        { desc = "save visual selection for focus mode" }
    )
    vim.keymap.set("n", "<localleader>vd", user.remove_user_range, { desc = "save visual selection for focus mode" })
    vim.keymap.set("n", "<localleader>vv", focus.user_ranges, { desc = "focus visual selection" })

    -- vim.keymap.set("n", "<leader>td", focus.todos, { desc = "focus visual selection" })

    vim.keymap.set("n", "<leader>fi", function()
        if vim.g.custom_focus_mode == nil or not vim.g.custom_focus_mode then
            vim.ui.input({
                prompt = "Focus on buffer text",
            }, function(input)
                focus.text({ input })
            end)
        else
            -- toggle off
            focus.text({})
        end
    end, { desc = "focus visual selection" })
end

--- @alias Extension "mini"

--- @param extension Extension
M.load = function(extension)
    if extension == "mini" then
        local extras = require("core.extensions.folds.extra")
        vim.keymap.set("n", "<leader>D", extras.focus_diff, { desc = "focus diffs" })
    end
end

return M
