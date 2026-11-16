local M = {}
local api = vim.api
local source = require("vcs.diff.source")
local namespace = api.nvim_create_namespace("vcs.diff.conflicts")
local label = "Unresolved conflict"

local function stamp(path)
    local stat = vim.uv.fs_stat(path)
    return stat and { stat.dev, stat.ino, stat.size, stat.mtime, stat.ctime }
end

local function unresolved(buf, id)
    local mark = api.nvim_buf_get_extmark_by_id(buf, namespace, id, { details = true })
    return #mark > 0 and not mark[3].invalid and mark[1] or nil
end

function M.open(buf, original, width)
    local lines = api.nvim_buf_get_lines(original, 0, -1, false)
    local blocks = source.conflicts(lines, width)
    local result, next_line = {}, 1
    for _, block in ipairs(blocks) do
        vim.list_extend(result, vim.list_slice(lines, next_line, block.first - 1))
        result[#result + 1] = ""
        block.row = #result - 1
        next_line = block.last + 1
    end
    vim.list_extend(result, vim.list_slice(lines, next_line))

    local path = api.nvim_buf_get_name(original)
    api.nvim_buf_set_name(buf, "ribbon-result://" .. buf .. "/" .. vim.fs.basename(path))
    local options = vim.bo[buf]
    options.buftype = "acwrite"
    options.buflisted = true
    options.bufhidden = "hide"
    options.undolevels = -1
    options.endofline = vim.bo[original].endofline
    options.filetype = vim.bo[original].filetype
    api.nvim_buf_set_lines(buf, 0, -1, false, result)
    options.undolevels = vim.bo[original].undolevels
    options.modified = false

    for _, block in ipairs(blocks) do
        block.id = api.nvim_buf_set_extmark(buf, namespace, block.row, 0, {
            end_row = block.row + 1,
            end_col = 0,
            end_right_gravity = false,
            invalidate = true,
            virt_text = { { label, "WarningMsg" } },
            virt_text_pos = "eol",
        })
    end

    local original_tick, disk_stamp = api.nvim_buf_get_changedtick(original), stamp(path)
    api.nvim_create_autocmd("BufWriteCmd", {
        buffer = buf,
        callback = function()
            for _, block in ipairs(blocks) do
                if unresolved(buf, block.id) then
                    error("Resolve all conflict rows before writing", 0)
                end
            end
            if not api.nvim_buf_is_valid(original) or api.nvim_buf_get_name(original) ~= path
                or original_tick ~= api.nvim_buf_get_changedtick(original)
                or not vim.deep_equal(disk_stamp, stamp(path))
            then
                error("Working file changed since this merge draft opened", 0)
            end
            local resolved = api.nvim_buf_get_lines(buf, 0, -1, false)
            if #source.conflicts(resolved, width) > 0 then
                error("Remove Git conflict markers before writing", 0)
            end

            local before = api.nvim_buf_get_lines(original, 0, -1, false)
            local was_modified = vim.bo[original].modified
            api.nvim_buf_set_lines(original, 0, -1, false, resolved)
            local ok, err = pcall(api.nvim_buf_call, original, function()
                vim.cmd.write()
            end)
            if not ok then
                api.nvim_buf_set_lines(original, 0, -1, false, before)
                vim.bo[original].modified = was_modified
                original_tick = api.nvim_buf_get_changedtick(original)
                error(err, 0)
            end
            original_tick, disk_stamp = api.nvim_buf_get_changedtick(original), stamp(path)
            vim.bo[buf].modified = false
        end,
    })

    for _, side in ipairs({ "ours", "theirs" }) do
        local name = "RibbonGet" .. side:sub(1, 1):upper() .. side:sub(2)
        api.nvim_buf_create_user_command(buf, name, function()
            local row = api.nvim_win_get_cursor(0)[1]
            if not M.pick(buf, blocks, row, side) then
                vim.notify("Cursor is outside an unresolved conflict row", vim.log.levels.WARN)
            end
        end, { desc = "Take " .. side .. " for the conflict under the cursor" })
    end
end

function M.pick(buf, blocks, row, side)
    for _, block in ipairs(blocks) do
        if unresolved(buf, block.id) == row - 1 then
            api.nvim_buf_set_lines(buf, row - 1, row, false, block[side])
            return true
        end
    end
    return false
end

return M
