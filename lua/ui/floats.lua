local M = {}

M.is_floating_win = function(winr)
    local cfg = vim.api.nvim_win_get_config(winr)
    return cfg.relative ~= "" or cfg.external
end

--- @class FloatOpts
--- @field title string
--- @field height ?number percent of editor or number of rows
--- @field width ?number percent of editor or number of columns
--- @field row ?number
--- @field col ?number
--- @field max_width ?number max total cols
--- @field max_height ?number max total rows
--- @field close_on_q ?boolean
--- @field bo ?table<string, any>
--- @field wo ?table<string, any>
--- @field bufnr ?integer
--- @field border ?string

local default_float_opts = {
    title = "",
    height = 0.32,
    width = 0.5,
    close_on_q = true,
    bo = {},
    wo = {},
    bufnr = -1,
    border = "rounded",
}

--- @param opts ?FloatOpts
--- @return integer bufnr,integer winr
M.open = function(opts)
    opts = opts or {}
    local bufnr = (opts.bufnr and opts.bufnr > 0) and opts.bufnr or vim.api.nvim_create_buf(true, true)
    local editor_width = vim.o.columns
    local editor_height = vim.o.lines
    local width = math.floor((opts.width or default_float_opts.width) * editor_width)
    width = opts.max_width and math.min(width, opts.max_width) or width
    local height = math.floor((opts.height or default_float_opts.height) * editor_height)
    height = opts.max_height and math.min(height, opts.max_height) or height
    if opts.height >= 1 then
        height = opts.height
    end
    if opts.width >= 1 then
        width = opts.width
    end
    local row = opts.row or (editor_height - height) / 2
    local col = opts.col or (editor_width - width) / 2

    local winr = vim.api.nvim_open_win(bufnr, true, {
        title = opts.title or default_float_opts.title,
        relative = "editor",
        row = row,
        col = col,
        width = width,
        height = height,
        style = "minimal",
        border = opts.border or default_float_opts.border,
    })

    for buf_opt, setting in pairs(opts.bo or default_float_opts.bo) do
        vim.api.nvim_set_option_value(buf_opt, setting, { buf = bufnr })
    end

    for win_opt, setting in pairs(opts.wo or default_float_opts.wo) do
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
