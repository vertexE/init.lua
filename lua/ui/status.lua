local M = {}

local api = vim.api
local snapshot = require("vcs.git_snapshot")
local namespace = api.nvim_create_namespace("user.status.window")
local spotify_namespace = api.nvim_create_namespace("user.status.spotify")
local WIDTH = 35
-- Group prefix consumes two cells; reserve one cell at right edge.
local CONTENT_WIDTH = WIDTH - 3
local state = { bufnr = -1, winr = -1, generation = 0 }

local function active()
    return api.nvim_buf_is_valid(state.bufnr) and api.nvim_win_is_valid(state.winr)
end

local function draw()
    if not active() then
        return
    end
    if api.nvim_win_get_width(state.winr) ~= WIDTH then
        api.nvim_win_set_width(state.winr, WIDTH)
    end
    local status = state.status or { files = {}, message = "Loading…" }
    local lines = {
        { { "   ", "MiniIconsGreen" }, { "editing ", "Comment" }, { vim.fn.fnamemodify(vim.fn.getcwd(), ":t"), "MiniIconsOrange" } },
        {},
        { { "   git", "Title" } },
    }
    local function file_row(path, prefix)
        local dir, name = path:match("^(.*/)([^/]+/?)$")
        local icon, hl = require("mini.icons").get(path:sub(-1) == "/" and "directory" or "file", path)
        local row = vim.list_extend(prefix, { { " " .. icon .. " ", hl }, { vim.fn.strtrans(name or path) } })
        table.insert(lines, row)
        if dir then
            table.insert(lines, { { "      " .. vim.fn.strtrans(dir), "Comment" } })
        end
    end
    if status.message then
        table.insert(lines, { { "    " .. status.message, "Comment" } })
    else
        local changed, deleted = 0, 0
        for _, file in pairs(status.files) do
            if file.worktree == "D" or (file.index == "D" and file.worktree ~= "?") then
                deleted = deleted + 1
            else
                changed = changed + 1
            end
        end
        table.insert(lines, { { string.format(" %d files changed", changed), "Comment" } })
        table.insert(lines, { { string.format(" %d files deleted", deleted), "Comment" } })
    end
    if status.added then
        table.insert(lines, {
            { " +" .. status.added, "MiniIconsGreen" },
            { " −" .. status.deleted, "MiniIconsRed" },
        })
    end
    local git_end = #lines
    table.insert(lines, {})
    local spotify_start = #lines + 1
    local spotify_rows, progress_row = require("spotify.ui").rows(CONTENT_WIDTH)
    vim.list_extend(lines, spotify_rows)
    local spotify_end = #lines
    table.insert(lines, {})
    table.insert(lines, { { "   goto", "Title" } })
    local goto_start = #lines
    local gotos = require("navigation.goto").list()
    for i, file in ipairs(gotos) do
        file_row(file.path, { { string.format(" %d ", i), "Comment" } })
    end
    if #gotos == 0 then
        table.insert(lines, { { "    No saved files", "Comment" } })
    end
    local grouped = {}
    local function group(first, last)
        table.insert(grouped, { { "╭" .. string.rep("─", WIDTH - 1), "WinSeparator" } })
        for i = first, last do
            table.insert(lines[i], 1, { "│ ", "WinSeparator" })
            table.insert(grouped, lines[i])
        end
        table.insert(grouped, { { "╰" .. string.rep("─", WIDTH - 1), "WinSeparator" } })
    end
    group(1, 1)
    table.insert(grouped, {})
    state.spotify_row = #grouped + 1
    state.spotify_progress = progress_row
    group(spotify_start, spotify_end)
    table.insert(grouped, {})
    group(3, git_end)
    table.insert(grouped, {})
    group(goto_start, #lines)
    vim.bo[state.bufnr].modifiable = true
    api.nvim_buf_clear_namespace(state.bufnr, namespace, 0, -1)
    api.nvim_buf_clear_namespace(state.bufnr, spotify_namespace, 0, -1)
    require("ui.extmarks").write_vlines_as_content(state.bufnr, namespace, grouped)
    vim.bo[state.bufnr].modifiable = false
end

local function draw_progress()
    if not active() or not state.spotify_row then
        return
    end
    local rows, progress_row = require("spotify.ui").rows(CONTENT_WIDTH)
    if not progress_row then
        return
    end
    if progress_row ~= state.spotify_progress then
        draw()
        return
    end
    -- Only progress/time rows change. Preserve Git, goto and metadata extmarks.
    local first = state.spotify_row + progress_row - 1
    local content = {}
    for i = progress_row, progress_row + 1 do
        table.insert(rows[i], 1, { "│ ", "WinSeparator" })
        local chunks = {}
        for _, chunk in ipairs(rows[i]) do
            chunks[#chunks + 1] = chunk[1]
        end
        content[#content + 1] = table.concat(chunks)
    end
    vim.bo[state.bufnr].modifiable = true
    api.nvim_buf_clear_namespace(state.bufnr, namespace, first, first + 2)
    api.nvim_buf_clear_namespace(state.bufnr, spotify_namespace, first, first + 2)
    api.nvim_buf_set_lines(state.bufnr, first, first + 2, false, content)
    for i = progress_row, progress_row + 1 do
        local col = 0
        for _, chunk in ipairs(rows[i]) do
            api.nvim_buf_set_extmark(state.bufnr, spotify_namespace, first + i - progress_row, col, {
                end_col = col + #chunk[1], hl_group = chunk[2],
            })
            col = col + #chunk[1]
        end
    end
    vim.bo[state.bufnr].modifiable = false
end

local function refresh()
    if not active() then
        return
    end
    local generation, cwd = state.generation, vim.fn.getcwd()
    snapshot.refresh(cwd, function(root, status)
        if not active() or generation ~= state.generation or cwd ~= vim.fn.getcwd() then
            return
        end
        state.root, state.status, state.cwd = root, status, cwd
        draw()
    end)
end

local function request_refresh()
    state.refresh_token = (state.refresh_token or 0) + 1
    local token, generation = state.refresh_token, state.generation
    vim.defer_fn(function()
        if generation == state.generation and token == state.refresh_token then
            refresh()
        end
    end, 200)
end

M.is_open = function()
    return active()
end

M.toggle_split = function()
    if active() then
        api.nvim_buf_delete(state.bufnr, { force = true })
        return
    end
    state.generation = state.generation + 1
    state.status = state.cwd == vim.fn.getcwd() and state.root and snapshot.get(state.root) or nil
    local bufnr, winr = require("ui.splits").vertical(nil, {
        wo = { number = false, relativenumber = false, statuscolumn = "", wrap = false, winfixwidth = true },
        bo = { buflisted = false, bufhidden = "wipe" },
        split = "left_most",
        width = WIDTH,
    })
    state.bufnr, state.winr = bufnr, winr
    local group = api.nvim_create_augroup("user.status.window", { clear = true })
    local timer = vim.uv.new_timer()
    timer:start(30000, 30000, vim.schedule_wrap(function()
        if active() and api.nvim_win_get_tabpage(state.winr) == api.nvim_get_current_tabpage() then
            refresh()
        end
    end))
    api.nvim_create_autocmd("BufWipeout", {
        buffer = bufnr,
        once = true,
        callback = function()
            require("spotify").stop()
            timer:stop()
            timer:close()
            state.bufnr, state.winr = -1, -1
            state.generation = state.generation + 1
            api.nvim_clear_autocmds({ group = group })
        end,
    })
    api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
        group = group,
        callback = function()
            if api.nvim_get_current_win() == state.winr then
                local keys = api.nvim_replace_termcodes("<C-w>l", true, false, true)
                api.nvim_feedkeys(keys, "n", false)
            end
        end,
    })
    api.nvim_create_autocmd({ "BufWritePost", "FocusGained" }, { group = group, callback = request_refresh })
    api.nvim_create_autocmd("DirChanged", {
        group = group,
        callback = function()
            state.generation = state.generation + 1
            state.root, state.status = nil, nil
            draw()
            request_refresh()
        end,
    })
    api.nvim_create_autocmd("User", { group = group, pattern = "GitStatusChanged", callback = request_refresh })
    api.nvim_create_autocmd("User", { group = group, pattern = { "GotoChanged", "StatusRedraw" }, callback = draw })
    api.nvim_create_autocmd("User", { group = group, pattern = "SpotifyChanged", callback = draw })
    api.nvim_create_autocmd("User", { group = group, pattern = "SpotifyProgress", callback = draw_progress })
    api.nvim_create_autocmd("ColorScheme", { group = group, callback = function()
        require("spotify.ui").highlights()
        draw()
    end })
    require("spotify.ui").highlights()
    require("spotify").setup()
    draw()
    refresh()
    require("spotify").start()
end

return M
