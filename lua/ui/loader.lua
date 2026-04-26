local M = {}

--- namespace ID  --> bufnr
--- @type table<integer,integer>
local active_loaders = {}

--- @type table<integer,integer>
local ns_to_extmark_id = {}

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
    local ext_id = vim.api.nvim_buf_set_extmark(bufnr, ns_id, start_row - 1, 0, {
        virt_lines = {
            {
                { string.rep(" ", dist_to_non_whitespace(lines[1])), "Comment" },
                { "Thinking...", "DiagnosticOk" },
            },
        },
        virt_lines_above = true,
    })
    ns_to_extmark_id[ns_id] = ext_id

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

--- get the line number of an active loader
--- @return integer the line number, 0-indexed
M.location = function(buf, ns)
    if ns_to_extmark_id[ns] == nil then
        vim.notify("(loader): failed to lookup extmark ID by ns ID", vim.log.levels.ERROR)
        return -1
    end

    local row = vim.api.nvim_buf_get_extmark_by_id(buf, ns, ns_to_extmark_id[ns], {})[1]
    return row
end

--- @param ns integer
M.stop = function(ns)
    if not active_loaders[ns] then
        return
    end

    vim.api.nvim_buf_clear_namespace(active_loaders[ns], ns, 0, -1)
end

return M
