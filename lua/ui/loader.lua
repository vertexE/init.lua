local M = {}

--- namespace ID  --> bufnr
--- @type table<integer,integer>
local active_loaders = {}

--- dist to first non whitespace char
--- @param s ?string
--- @return integer
local dist_to_non_whitespace = function(s)
    if not s then
        return 0
    end

    local _, _end = s:find("^[%s]*")
    return _end and _end or 0
end

M.start = function(bufnr, start_row, end_row, apply_ghost)
    local loader_id = #active_loaders
    local ns_id = vim.api.nvim_create_namespace("user_loader_vt_" .. loader_id)
    local lines = vim.api.nvim_buf_get_lines(bufnr, start_row - 1, end_row, false)
    vim.api.nvim_buf_set_extmark(bufnr, ns_id, start_row - 1, 0, {
        virt_lines = {
            {
                { string.rep(" ", dist_to_non_whitespace(lines[1])), "Comment" },
                { "  Thinking...", "DiagnosticOk" },
            },
        },
        virt_lines_above = true,
    })

    if apply_ghost then
        for i, line in ipairs(lines) do
            vim.api.nvim_buf_set_extmark(bufnr, ns_id, start_row - 1 + i - 1, 0, {
                hl_group = "Comment",
                end_col = #line,
            })
        end
    end

    active_loaders[ns_id] = bufnr

    return ns_id
end

--- @param ns integer
M.stop = function(ns)
    if not active_loaders[ns] then
        return
    end

    vim.api.nvim_buf_clear_namespace(active_loaders[ns], ns, 0, -1)
end

return M
