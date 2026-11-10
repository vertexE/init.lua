local M = {}

--- @param prompt string
--- @param callback fun(accepted: boolean)
M.open = function(prompt, callback)
    local editor_width = vim.o.columns
    local editor_height = vim.o.lines - vim.o.cmdheight
    local prompt_width = vim.fn.strdisplaywidth(prompt)
    local width = math.max(1, math.min(editor_width - 2, math.max(24, prompt_width)))
    local height = math.max(1, math.min(editor_height - 2, math.ceil(prompt_width / width) + 1))
    local row = (editor_height - height) / 2
    local col = (editor_width - width) / 2

    local float_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[float_buf].bufhidden = "wipe"
    local winr = vim.api.nvim_open_win(float_buf, true, {
        relative = "editor",
        row = row,
        col = col,
        width = width,
        height = height,
        style = "minimal",
        border = "rounded",
    })

    vim.api.nvim_buf_set_lines(float_buf, 0, -1, false, { prompt, "(y/<enter>)/(n/q)" })
    vim.bo[float_buf].modifiable = false
    vim.wo[winr].scrolloff = 0
    vim.wo[winr].wrap = true

    local ns = vim.api.nvim_create_namespace("user.confirm.accept")
    vim.api.nvim_buf_set_extmark(float_buf, ns, 0, 0, {
        end_col = #prompt,
        hl_group = "MiniIconsPurple",
    })
    vim.api.nvim_buf_set_extmark(float_buf, ns, 1, 0, {
        end_col = #"(y/<enter>)/(n/q)",
        hl_group = "Comment",
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
