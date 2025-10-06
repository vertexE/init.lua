local M = {}

--- @class CenterOpts
--- @field title string
--- @field height ?number
--- @field width ?number
--- @field close_on_q ?boolean
--- @field bo ?table<string, any>
--- @field wo ?table<string, any>

local center_opts = {
    title = "",
    height = 0.32,
    width = 0.5,
    close_on_q = true,
    bo = {},
    wo = {},
}

--- @param opts ?CenterOpts
--- @return integer bufnr,integer winr
M.center = function(opts)
    opts = opts or {}
    local bufnr = vim.api.nvim_create_buf(true, true)
    local editor_width = vim.o.columns
    local editor_height = vim.o.lines
    local width = math.floor((opts.width or center_opts.width) * editor_width)
    local height = math.floor((opts.height or center_opts.height) * editor_height)
    local row = (editor_height - height) / 2
    local col = (editor_width - width) / 2

    local winr = vim.api.nvim_open_win(bufnr, true, {
        title = opts.title or center_opts.title,
        relative = "editor",
        row = row,
        col = col,
        width = width,
        height = height,
        style = "minimal",
        border = "rounded",
    })

    for buf_opt, setting in pairs(opts.bo or center_opts.bo) do
        vim.api.nvim_set_option_value(buf_opt, setting, { buf = bufnr })
    end

    for win_opt, setting in pairs(opts.wo or center_opts.wo) do
        vim.api.nvim_set_option_value(win_opt, setting, { win = winr })
    end

    if opts.close_on_q == nil or opts.close_on_q then
        vim.keymap.set("n", "q", function()
            vim.api.nvim_buf_delete(bufnr, { force = true })
        end, { buffer = bufnr })
    end

    return bufnr, winr
end

return M
