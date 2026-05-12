local M = {}

local move = require("editor.move")

local state = {
    --- @type boolean
    change_stream_active = false,
    --- @type table<editor.RequestedChange>
    changes = {},
    --- @type integer
    active_change_index = 1,
    --- @type integer incremented on each start so stale deferred callbacks self-cancel
    generation = 0,
}

--- @class editor.RequestedChange
--- @field type "INSERT"|"DELETE"|"REPLACE"
--- @field file_path string file path relative to root of current working directory.
--- @field start_line_nr integer 0-based indexed
--- @field end_line_nr integer 0-based indexed
--- @field lines string[]
--- @field extmark_location_id integer|nil

--- inserts character by character at position row, calls on_complete when done
--- @param on_complete fun()|nil
M.insert = function(winr, bufnr, start_row, to_insert, on_complete)
    local empty_lines = {}
    for _ = 1, #to_insert do
        table.insert(empty_lines, "")
    end
    vim.api.nvim_buf_set_lines(bufnr, start_row, start_row, false, empty_lines)

    local chars = {}
    for line_idx, line in ipairs(to_insert) do
        local line_row = start_row + line_idx - 1
        for i = 1, #line do
            table.insert(chars, { row = line_row, char = line:sub(i, i) })
        end
    end

    if #chars == 0 then
        if on_complete then
            on_complete()
        end
        return
    end

    local row_cols = {}
    for i = 0, #to_insert - 1 do
        row_cols[start_row + i] = 0
    end

    local char_index = 1
    local current_row = start_row
    local insert_timer = vim.uv.new_timer()
    if not insert_timer then
        vim.notify("(stream): failed to create insert timer", vim.log.levels.ERROR)
        if on_complete then
            on_complete()
        end
        return
    end

    insert_timer:start(
        0,
        60,
        vim.schedule_wrap(function()
            if char_index > #chars then
                insert_timer:stop()
                insert_timer:close()
                if on_complete then
                    on_complete()
                end
                return
            end

            local entry = chars[char_index]
            local row = entry.row

            if row ~= current_row and (row - start_row) > 30 then
                current_row = row
                vim.api.nvim_win_call(winr, function()
                    vim.cmd("normal! \x05")
                end)
            end

            local col = row_cols[row]
            vim.api.nvim_buf_set_text(bufnr, row, col, row, col, { entry.char })
            row_cols[row] = col + 1
            char_index = char_index + 1
        end)
    )
end

--- MVP we'll just delete the whole block for now
M.delete = function(winr, bufnr, start_row, end_row)
    vim.api.nvim_buf_set_lines(bufnr, start_row, end_row + 1, false, {})
end

--- returns line_nr (0 indexed) of the requested change regardless of any edits
--- made to the buffer using the extmark_location_id row instead.
--- @param request editor.RequestedChange
--- @return integer
local find_requested_change = function(request)
    local bufnr = vim.fn.bufadd(request.file_path)
    local ns = vim.api.nvim_create_namespace("user.editor.stream")
    local pos = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns, request.extmark_location_id, {})
    return pos[1]
end

--- for all requested change files, clear extmarks
--- @param requests table<editor.RequestedChange>
local clear_change_markers = function(requests)
    local ns = vim.api.nvim_create_namespace("user.editor.stream")
    local seen = {}
    for _, request in ipairs(requests) do
        if not seen[request.file_path] then
            seen[request.file_path] = true
            local bufnr = vim.fn.bufadd(request.file_path)
            vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
        end
    end
end

--- mark all change locations so as we apply a change
--- a change set we won't have to track line number offsets.
--- @param request editor.RequestedChange
--- @return editor.RequestedChange
local mark_requested_changes = function(request)
    local bufnr = vim.fn.bufadd(request.file_path)
    vim.fn.bufload(bufnr)
    local ns = vim.api.nvim_create_namespace("user.editor.stream")
    local id = vim.api.nvim_buf_set_extmark(bufnr, ns, request.start_line_nr, 0, {
        virt_text = { { "◆", "Identifier" } },
        virt_text_pos = "eol",
    })
    request.extmark_location_id = id
    return request
end

--- parses a features change set directory
--- @param feature_dir string
--- @return table<editor.RequestedChange>
local read_requested_changes = function(feature_dir)
    local changes = {}
    local handle = vim.uv.fs_scandir(feature_dir)
    if not handle then
        return changes
    end

    while true do
        local name, ftype = vim.uv.fs_scandir_next(handle)
        if not name then
            break
        end
        if ftype == "file" then
            local path = feature_dir .. "/" .. name
            local fd = io.open(path, "r")
            if fd then
                local content = fd:read("*a")
                fd:close()
                local ok, parsed = pcall(vim.json.decode, content)
                if ok and parsed then
                    table.insert(changes, parsed)
                end
            end
        end
    end

    table.sort(changes, function(a, b)
        if a.file_path ~= b.file_path then
            return a.file_path < b.file_path
        end
        return a.start_line_nr < b.start_line_nr
    end)

    return changes
end

local make_requested_changes = function(winr, changes)
    state.changes = changes
    state.active_change_index = 1
    state.generation = state.generation + 1
    local gen = state.generation

    local function process_next()
        if not state.change_stream_active or gen ~= state.generation then
            return
        end

        if state.active_change_index > #state.changes then
            clear_change_markers(state.changes)
            state.change_stream_active = false
            return
        end

        local request = state.changes[state.active_change_index]
        state.active_change_index = state.active_change_index + 1

        local line_nr = find_requested_change(request)
        local bufnr = vim.fn.bufadd(request.file_path)

        move.jump_to(winr, bufnr, line_nr)

        local function on_done()
            vim.defer_fn(process_next, 1500)
        end

        if request.type == "INSERT" then
            M.insert(winr, bufnr, line_nr, request.lines, on_done)
        elseif request.type == "DELETE" then
            M.delete(winr, bufnr, line_nr, line_nr + (request.end_line_nr - request.start_line_nr))
            on_done()
        elseif request.type == "REPLACE" then
            M.delete(winr, bufnr, line_nr, line_nr + (request.end_line_nr - request.start_line_nr))
            M.insert(winr, bufnr, line_nr, request.lines, on_done)
        end
    end

    vim.defer_fn(process_next, 1500)
end

--- given a window and a relative path to a change set folder,
--- startup follow mode and implement the change set.
--- @param winr integer
--- @param feature_directory string
M.start_change_stream = function(winr, feature_directory)
    local changes = read_requested_changes(feature_directory)
    changes = vim.tbl_map(mark_requested_changes, changes)
    state.change_stream_active = true
    make_requested_changes(winr, changes)
end

--- reset state completely
M.stop_change_stream = function()
    state.change_stream_active = false
    state.generation = state.generation + 1
    if state.changes and #state.changes > 0 then
        clear_change_markers(state.changes)
        state.changes = {}
    end
    state.active_change_index = 1
end

return M
