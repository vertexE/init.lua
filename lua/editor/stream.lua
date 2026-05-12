local M = {}

local move = require("editor.move")
local git_parse = require("vcs.git_parse")

local state = {
    --- @type boolean
    change_stream_active = false,
    --- @type git.DiffFile[]
    diff_files = {},
    --- @type {fi: integer, hi: integer}[]
    queue = {},
    --- @type integer
    active_queue_index = 1,
    --- @type integer incremented on each start so stale deferred callbacks self-cancel
    generation = 0,
}

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
        40,
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

--- @param bufnr integer
--- @param start_row integer 0-indexed
--- @param count integer number of lines to remove
M.delete = function(bufnr, start_row, count)
    vim.api.nvim_buf_set_lines(bufnr, start_row, start_row + count, false, {})
end

local ns = function()
    return vim.api.nvim_create_namespace("user.editor.stream")
end

--- @param diff_file git.DiffFile
--- @param hunk git.Hunk
local mark_hunk = function(diff_file, hunk)
    local bufnr = vim.fn.bufadd(diff_file.file)
    vim.fn.bufload(bufnr)
    local row = math.max(0, hunk.at - 1)
    local id = vim.api.nvim_buf_set_extmark(bufnr, ns(), row, 0, {
        virt_text = { { "◆", "Identifier" } },
        virt_text_pos = "eol",
        right_gravity = false,
    })
    hunk.extmark_id = id
end

--- returns current 0-indexed row of hunk via its extmark
--- @param diff_file git.DiffFile
--- @param hunk git.Hunk
--- @return integer
local find_hunk_position = function(diff_file, hunk)
    local bufnr = vim.fn.bufadd(diff_file.file)
    local pos = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns(), hunk.extmark_id, {})
    return pos[1]
end

--- @param diff_files git.DiffFile[]
local clear_all_markers = function(diff_files)
    local seen = {}
    for _, df in ipairs(diff_files) do
        if not seen[df.file] then
            seen[df.file] = true
            local bufnr = vim.fn.bufadd(df.file)
            vim.api.nvim_buf_clear_namespace(bufnr, ns(), 0, -1)
        end
    end
end

--- @param patch_path string
--- @return git.DiffFile[]
local read_patch_file = function(patch_path)
    local fd = io.open(patch_path, "r")
    if not fd then
        vim.notify("(stream): could not open patch file: " .. patch_path, vim.log.levels.ERROR)
        return {}
    end
    local content = fd:read("*a")
    fd:close()
    return git_parse.parse_git_diff(content)
end

local make_changes = function(winr, diff_files)
    state.diff_files = diff_files
    state.generation = state.generation + 1
    local gen = state.generation

    state.queue = {}
    for fi, df in ipairs(diff_files) do
        for hi in ipairs(df.changes) do
            table.insert(state.queue, { fi = fi, hi = hi })
        end
    end
    state.active_queue_index = 1

    local function process_next()
        if not state.change_stream_active or gen ~= state.generation then
            return
        end

        if state.active_queue_index > #state.queue then
            clear_all_markers(state.diff_files)
            state.change_stream_active = false
            return
        end

        local entry = state.queue[state.active_queue_index]
        state.active_queue_index = state.active_queue_index + 1

        local diff_file = state.diff_files[entry.fi]
        local hunk = diff_file.changes[entry.hi]
        local line_nr = find_hunk_position(diff_file, hunk)
        local bufnr = vim.fn.bufadd(diff_file.file)

        local function on_done()
            local last_for_file = true
            for i = state.active_queue_index, #state.queue do
                if state.queue[i].fi == entry.fi then
                    last_for_file = false
                    break
                end
            end
            if diff_file.is_deleted and last_for_file then
                vim.fn.delete(diff_file.file)
            end
            vim.defer_fn(process_next, 1500)
        end

        move.jump_to(winr, bufnr, line_nr)

        if hunk.remove_count == 0 then
            M.insert(winr, bufnr, line_nr, hunk.lines, on_done)
        elseif #hunk.lines == 0 then
            M.delete(bufnr, line_nr, hunk.remove_count)
            on_done()
        else
            M.delete(bufnr, line_nr, hunk.remove_count)
            M.insert(winr, bufnr, line_nr, hunk.lines, on_done)
        end
    end

    vim.defer_fn(process_next, 1500)
end

--- given a window and a path to a unified diff patch file,
--- startup follow mode and implement the changes.
--- @param winr integer
--- @param patch_file_path string
M.start_change_stream = function(winr, patch_file_path)
    local diff_files = read_patch_file(patch_file_path)
    if #diff_files == 0 then
        vim.notify("(stream): no changes in patch", vim.log.levels.WARN)
        return
    end
    for _, df in ipairs(diff_files) do
        for _, hunk in ipairs(df.changes) do
            mark_hunk(df, hunk)
        end
    end
    state.change_stream_active = true
    make_changes(winr, diff_files)
end

--- reset state completely
M.stop_change_stream = function()
    state.change_stream_active = false
    state.generation = state.generation + 1
    if state.diff_files and #state.diff_files > 0 then
        clear_all_markers(state.diff_files)
        state.diff_files = {}
    end
    state.queue = {}
    state.active_queue_index = 1
end

return M
