local M = {}

local floats = require("ui.floats")

--- textarea will open a centered float and
--- use the buffer content as input to a callback
--- <enter> in normal mode submits the content
--- also "prompt" is float title

--- @class TextareaOpts
--- @field prompt ?string
--- @field height ?integer
--- @field width ?integer
--- @field row ?integer
--- @field col ?integer
--- @field content ?string
--- @field backdrop ?boolean

--- @alias TextareaCallback fun(input: string[])

---comment
---@param opts ?TextareaOpts
---@param callback TextareaCallback
M.open = function(opts, callback)
    opts = opts or {}

    local backdrop_winr
    if opts.backdrop then
        vim.api.nvim_set_hl(0, "TextareaBackdrop", { bg = "#000000" })

        local backdrop_bufnr = vim.api.nvim_create_buf(false, true)
        backdrop_winr = vim.api.nvim_open_win(backdrop_bufnr, false, {
            relative = "editor",
            row = 0,
            col = 0,
            width = vim.o.columns,
            height = vim.o.lines,
            style = "minimal",
            focusable = false,
            zindex = 40,
        })

        vim.wo[backdrop_winr].winhighlight = "Normal:TextareaBackdrop"
        vim.wo[backdrop_winr].winblend = 40
        vim.bo[backdrop_bufnr].bufhidden = "wipe"
    end

    local bufnr, winr = floats.open({
        title = opts.prompt,
        height = opts.height or 0.10,
        width = opts.width or 0.4,
        row = opts.row,
        col = opts.col,
        bo = { filetype = "markdown", buftype = "nowrite" },
        wo = { wrap = true, number = false, relativenumber = false },
        close_on_q = true,
    })

    if backdrop_winr then
        vim.api.nvim_create_autocmd("WinClosed", {
            pattern = tostring(winr),
            once = true,
            callback = function()
                if vim.api.nvim_win_is_valid(backdrop_winr) then
                    vim.api.nvim_win_close(backdrop_winr, true)
                end
            end,
        })
    end

    if opts.content ~= nil then
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(opts.content, "\n"))
    end

    vim.cmd("startinsert!")

    vim.keymap.set("n", "<esc>", function()
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end, { buffer = bufnr })

    vim.keymap.set("n", "<enter>", function()
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        vim.api.nvim_buf_delete(bufnr, { force = true })
        callback(lines)
    end, { buffer = bufnr })
end

return M
