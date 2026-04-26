local M = {}

--- @class ui.loader
--- @field bufnr integer
--- @field extmark_id integer
--- @field frame integer

--- namespace ID  --> bufnr
--- @type table<integer,ui.loader>
local active_loaders = {}

--- @type table<integer,integer>
-- local ns_to_extmark_id = {}

local counter = 0

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

local frames = {
    "⣾",
    "⣽",
    "⣻",
    "⢿",
    "⡿",
    "⣟",
    "⣯",
    "⣷",
}

local draw_loop = function(bufnr, ns_id, start_row, line)
    local timer = vim.loop.new_timer()
    timer:start(
        0,
        100,
        vim.schedule_wrap(function()
            local row = M.location(bufnr, ns_id)
            if not active_loaders[ns_id] then
                timer:stop()
                timer:close()
                return
            end

            vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
            local ext_id = vim.api.nvim_buf_set_extmark(bufnr, ns_id, row >= 0 and row or (start_row - 1), 0, {
                virt_lines = {
                    {
                        { string.rep(" ", dist_to_non_whitespace(line)), "Comment" },
                        {
                            string.format("Thinking %s", frames[active_loaders[ns_id].frame % #frames + 1]),
                            "DiagnosticOk",
                        },
                    },
                },
                virt_lines_above = true,
            })
            active_loaders[ns_id].frame = active_loaders[ns_id].frame + 1
            active_loaders[ns_id].extmark_id = ext_id
        end)
    )
end

M.start = function(bufnr, start_row, end_row, apply_ghost)
    local ns_id = vim.api.nvim_create_namespace("user_loader_vt_" .. counter)
    counter = counter + 1
    active_loaders[ns_id] = {
        bufnr = bufnr,
        extmark_id = -1, -- set in schedule_draw
        frame = 1,
    }
    local lines = vim.api.nvim_buf_get_lines(bufnr, start_row - 1, end_row, false)
    draw_loop(bufnr, ns_id, start_row, lines[1])

    -- TODO: refactor ghost
    -- if apply_ghost then
    --     for i, line in ipairs(lines) do
    --         vim.api.nvim_buf_set_extmark(bufnr, ns_id, start_row - 1 + i - 1, 0, {
    --             hl_group = "Comment",
    --             end_col = #line,
    --         })
    --     end
    -- end

    return ns_id
end

--- get the line number of an active loader
--- @return integer the line number, 0-indexed
M.location = function(buf, ns)
    if not active_loaders[ns] or active_loaders[ns].extmark_id < 0 then
        return -1
    end

    local row = vim.api.nvim_buf_get_extmark_by_id(buf, ns, active_loaders[ns].extmark_id, {})[1]
    return row
end

--- @param ns integer
M.stop = function(ns)
    if not active_loaders[ns] then
        return
    end

    vim.api.nvim_buf_clear_namespace(active_loaders[ns].bufnr, ns, 0, -1)
    active_loaders[ns] = nil
end

return M
