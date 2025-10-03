local M = {}

--- @param prompt string
--- @param callback fun(accepted: boolean)
M.open = function(prompt, callback)
    local editor_width = vim.o.columns
    local editor_height = vim.o.lines
    local width = #prompt + 10
    local height = 3
    local row = (editor_height - height) / 2
    local col = (editor_width - width) / 2

    local float_buf = vim.api.nvim_create_buf(false, true)
    local winr = vim.api.nvim_open_win(float_buf, true, {
        relative = "editor",
        row = row,
        col = col,
        width = width,
        height = height,
        style = "minimal",
        border = "rounded",
    })

    vim.api.nvim_buf_set_lines(float_buf, 0, -1, false, { "", "" })
    vim.wo[winr].scrolloff = 0

    vim.api.nvim_buf_set_extmark(float_buf, vim.api.nvim_create_namespace("user.confirm.accept"), 0, 0, {
        virt_text = { { prompt, "MiniIconsPurple" } },
        virt_lines = { { { "(y/<enter>)/(n/q)", "Comment" } } },
        virt_text_pos = "eol",
    })
    vim.keymap.set("n", "y", function()
        if vim.api.nvim_win_is_valid(winr) then
            vim.api.nvim_win_close(winr, true)
        end
        callback(true)
    end, { buffer = float_buf })
    vim.keymap.set("n", "<enter>", function()
        if vim.api.nvim_win_is_valid(winr) then
            vim.api.nvim_win_close(winr, true)
        end
        callback(true)
    end, { buffer = float_buf })
    vim.keymap.set("n", "n", function()
        if vim.api.nvim_win_is_valid(winr) then
            vim.api.nvim_win_close(winr, true)
        end
        callback(false)
    end, { buffer = float_buf })
    vim.keymap.set("n", "q", function()
        if vim.api.nvim_win_is_valid(winr) then
            vim.api.nvim_win_close(winr, true)
        end
        callback(false)
    end, { buffer = float_buf })
end

return M
