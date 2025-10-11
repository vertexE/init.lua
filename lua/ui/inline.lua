local M = {}

local tbl = require("tbl")

--- @class InlineOpts
--- @field title ?string|table<string> virtual text title
--- @field height ?number percent of editor
--- @field width ?number percent of editor
--- @field close_on_q ?boolean
--- @field bo ?table<string, any>
--- @field wo ?table<string, any>

local inline_opts = {
    height = 3,
    width = 120,
    close_on_q = false,
    bo = {},
    wo = {},
}

--- @alias InlineCallback fun(input: string[])

--- @param opts ?InlineOpts
---@param callback InlineCallback
--- @return integer bufnr,integer winr
M.cursor = function(opts, callback)
    opts = opts or {}
    local requesting_bufnr = vim.api.nvim_get_current_buf()
    local bufnr = vim.api.nvim_create_buf(true, true)
    local width = opts.width or inline_opts.width
    local height = opts.height or inline_opts.height
    local pos = vim.fn.getpos(".")
    local line = pos[2]
    local col = pos[3]

    local winr = vim.api.nvim_open_win(bufnr, true, {
        relative = "cursor",
        width = width,
        height = height,
        style = "minimal",
        border = "none",
        row = 0,
        col = -col + 1,
    })

    local ns = vim.api.nvim_create_namespace("user.inline.cursor")
    -- not the current line but the line above
    vim.api.nvim_buf_set_extmark(requesting_bufnr, ns, math.max(line - 2, 0), 0, {
        virt_lines = tbl.rep({}, {}, height),
        virt_lines_above = math.max(line - 2, 0) == 0,
    })

    if opts.title then
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "", "" })
        local inline_ns = vim.api.nvim_create_namespace("user.inline.cursor.textarea")
        vim.api.nvim_buf_set_extmark(bufnr, inline_ns, 0, 0, {
            virt_text = type(opts.title) == "table" and { { unpack(opts.title) } } or { { opts.title, "Comment" } },
        })
        vim.api.nvim_win_set_cursor(winr, { 2, 0 })
    end

    for buf_opt, setting in pairs(opts.bo or inline_opts.bo) do
        vim.api.nvim_set_option_value(buf_opt, setting, { buf = bufnr })
    end

    for win_opt, setting in pairs(opts.wo or inline_opts.wo) do
        vim.api.nvim_set_option_value(win_opt, setting, { win = winr })
    end

    vim.cmd("startinsert!")

    if opts.close_on_q == nil or opts.close_on_q then
        vim.keymap.set("n", "q", function()
            vim.api.nvim_buf_delete(bufnr, { force = true })
            vim.api.nvim_buf_clear_namespace(requesting_bufnr, ns, 0, -1)
        end, { buffer = bufnr })
    end

    vim.keymap.set("n", "<esc>", function()
        vim.api.nvim_buf_delete(bufnr, { force = true })
        vim.api.nvim_buf_clear_namespace(requesting_bufnr, ns, 0, -1)
    end, { buffer = bufnr })

    vim.keymap.set("n", "<enter>", function()
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        vim.api.nvim_buf_delete(bufnr, { force = true })
        vim.api.nvim_buf_clear_namespace(requesting_bufnr, ns, 0, -1)
        callback(lines)
    end, { buffer = bufnr })

    return bufnr, winr
end

return M
