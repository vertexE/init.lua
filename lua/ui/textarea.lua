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
--- @field content ?string

--- @alias TextareaCallback fun(input: string[])

---comment
---@param opts ?TextareaOpts
---@param callback TextareaCallback
M.open = function(opts, callback)
    opts = opts or {}
    local bufnr = floats.center({
        title = opts.prompt,
        height = opts.height or 0.10,
        width = opts.width or 0.4,
        bo = { filetype = "markdown", buftype = "nowrite" },
        wo = { wrap = true, number = false, relativenumber = false },
        close_on_q = true,
    })

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
