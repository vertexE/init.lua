local M = {}
local api = vim.api
local source = require("vcs.diff.source")
local render = require("vcs.diff.render")
local draft = require("vcs.diff.draft")
local sessions = {}
local drafts = {}
local connector_width = 3

local function warn(message)
    vim.notify(message, vim.log.levels.WARN)
end

local function scratch()
    local buf = api.nvim_create_buf(false, true)
    vim.bo[buf].bufhidden = "wipe"
    return buf
end

local function split(session, buf, direction, options)
    local win = api.nvim_open_win(buf, false, { win = session.target, split = direction })
    session.windows[win] = buf
    vim.wo[win].diff = false
    vim.wo[win].scrollbind = false
    vim.wo[win].cursorbind = false
    vim.wo[win].wrap = false
    vim.wo[win].foldenable = false
    for name, value in pairs(options) do
        vim.wo[win][name] = value
    end
    return win
end

local function reference(session, text, direction, label)
    local buf = scratch()
    local lines = vim.split(text:gsub("\n$", ""), "\n", { plain = true })
    api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.bo[buf].filetype = vim.bo[session.buf].filetype
    return split(session, buf, direction, {
        winbar = label,
        number = false,
        relativenumber = false,
        signcolumn = "no",
        statuscolumn = "",
    })
end

local function size_gutter(context)
    local left = api.nvim_win_get_buf(context.left)
    local right = api.nvim_win_get_buf(context.right)
    local lines = math.max(api.nvim_buf_line_count(left), api.nvim_buf_line_count(right))
    local width = math.max(3, #tostring(lines) + 1)
    if width ~= context.number_width then
        context.number_width = width
        api.nvim_win_set_width(context.gutter, connector_width + 2 * width - 2)
    end
end

local function pair(session, left, right, direction)
    local buf = scratch()
    vim.bo[buf].modifiable = false
    local gutter = split(session, buf, direction, {
        winbar = "",
        number = false,
        relativenumber = false,
        signcolumn = "no",
        statuscolumn = "",
        foldcolumn = "0",
        winfixwidth = true,
        cursorline = false,
        cursorcolumn = false,
        spell = false,
        list = false,
    })
    local context = {
        left = left,
        right = right,
        gutter = gutter,
        canvas = scratch(),
        image = {},
    }
    session.pairs[#session.pairs + 1] = context
    size_gutter(context)
end

local function close(session)
    sessions[session.original] = nil
    sessions[session.buf] = nil
    if session.group then
        api.nvim_del_augroup_by_id(session.group)
    end
    for _, name in ipairs(session.commands) do
        if api.nvim_buf_is_valid(session.buf) then
            api.nvim_buf_del_user_command(session.buf, name)
        end
    end
    for _, context in ipairs(session.pairs) do
        render.close(context)
        if context.float and api.nvim_win_is_valid(context.float) then
            api.nvim_win_close(context.float, true)
        end
        if api.nvim_buf_is_valid(context.canvas) then
            api.nvim_buf_delete(context.canvas, { force = true })
        end
    end
    for win, buf in pairs(session.windows) do
        if win ~= session.target and api.nvim_win_is_valid(win) and api.nvim_win_get_buf(win) == buf then
            api.nvim_win_close(win, true)
        end
    end
    if session.buf ~= session.original and api.nvim_buf_is_valid(session.buf)
        and not vim.bo[session.buf].modified and #vim.fn.win_findbuf(session.buf) == 0
    then
        api.nvim_buf_delete(session.buf, { force = false })
        drafts[session.original] = nil
    end
    if api.nvim_win_is_valid(session.target) then
        for name, value in pairs(session.options or {}) do
            vim.wo[session.target][name] = value
        end
    end
end

local function refresh(session)
    for win, buf in pairs(session.windows) do
        if not api.nvim_win_is_valid(win) or api.nvim_win_get_buf(win) ~= buf then
            close(session)
            return
        end
    end
    if api.nvim_get_current_tabpage() ~= session.tab then
        return
    end
    local tick = api.nvim_buf_get_changedtick(session.buf)
    local eol = vim.bo[session.buf].endofline
    local changed = tick ~= session.tick or eol ~= session.eol
    if changed then
        local current = source.buffer_text(session.buf)
        render.hunks(session.pairs[1], session.ours, current)
        if session.theirs then
            render.hunks(session.pairs[2], current, session.theirs)
        end
        render.highlight(session.pairs)
        session.tick, session.eol = tick, eol
    end
    for _, context in ipairs(session.pairs) do
        if changed then
            size_gutter(context)
        end
        render.paint(context)
    end
    if changed and #api.nvim_list_uis() > 0 then
        vim.cmd.redraw({ bang = true })
    end
end

local function sync_scroll(session)
    if api.nvim_get_current_tabpage() ~= session.tab then
        return
    end
    local moved, delta
    for _, win in ipairs(session.documents) do
        if not api.nvim_win_is_valid(win) or api.nvim_win_get_buf(win) ~= session.windows[win] then
            return
        end
        local top = vim.fn.getwininfo(win)[1].topline
        local previous = session.toplines[win]
        session.toplines[win] = top
        if previous and top ~= previous and (not moved or win == api.nvim_get_current_win()) then
            moved, delta = win, top - previous
        end
    end
    if not moved then
        return
    end
    for _, win in ipairs(session.documents) do
        if win ~= moved then
            session.toplines[win] = api.nvim_win_call(win, function()
                local view = vim.fn.winsaveview()
                local count = api.nvim_buf_line_count(0)
                view.topline = math.min(count, math.max(1, view.topline + delta))
                view.lnum = math.min(count, math.max(1, view.lnum + delta))
                vim.fn.winrestview(view)
                return vim.fn.line("w0")
            end)
        end
    end
end

local function watch(session)
    session.group = api.nvim_create_augroup("vcs.diff." .. session.target, { clear = true })
    local function queue()
        if session.pending then
            return
        end
        session.pending = true
        vim.schedule(function()
            session.pending = false
            if sessions[session.buf] == session then
                refresh(session)
            end
        end)
    end

    api.nvim_create_autocmd("WinScrolled", {
        group = session.group,
        callback = function()
            sync_scroll(session)
            queue()
        end,
    })
    api.nvim_create_autocmd({ "WinResized", "VimResized", "WinClosed", "BufWinEnter", "UIEnter", "UILeave" }, {
        group = session.group,
        callback = queue,
    })
    api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "TextChangedP" }, {
        group = session.group,
        buffer = session.buf,
        callback = queue,
    })
    api.nvim_create_autocmd("OptionSet", {
        group = session.group,
        pattern = { "endofline", "winbar" },
        callback = queue,
    })
    api.nvim_create_autocmd({ "ColorScheme", "TabEnter" }, {
        group = session.group,
        callback = function()
            for _, context in ipairs(session.pairs) do
                render.invalidate(context)
            end
            queue()
        end,
    })
    api.nvim_create_autocmd("VimLeavePre", {
        group = session.group,
        callback = function()
            for _, context in ipairs(session.pairs) do
                render.invalidate(context)
            end
        end,
    })
end

local function stage_command(session, entry)
    local name = "RibbonStageHunk"
    api.nvim_buf_create_user_command(session.buf, name, function(opts)
        if source.unmerged(session.buf, entry) then
            warn("Use :RibbonMerge to resolve the conflict first")
            return
        end
        local gitsigns = require("gitsigns")
        if not gitsigns.get_hunks(session.buf) then
            warn("Gitsigns is not attached to this file")
            return
        end
        local range = opts.range > 0 and { opts.line1, opts.line2 } or nil
        gitsigns.stage_hunk(range)
    end, { desc = "Stage a hunk through Gitsigns", range = true })
    table.insert(session.commands, name)
end

function M.open(merge, entry)
    local current = api.nvim_get_current_buf()
    local buf = vim.b[current].ribbon_original or current
    if merge == nil and entry then
        local ok, result = pcall(source.unmerged, buf, entry)
        if not ok then
            warn(result)
            return
        end
        merge = result
    end
    if current ~= buf and not merge then
        warn("Open the working file to compare it against HEAD")
        return
    end
    local existing = sessions[buf]
    if existing then
        if (existing.theirs ~= nil) == merge and api.nvim_win_is_valid(existing.target) then
            api.nvim_set_current_win(existing.target)
            return
        end
        warn("Close the current ribbon view for this file first")
        return
    end

    local ok, ours, theirs, marker_width = pcall(source.read, buf, merge, entry)
    if not ok then
        warn(ours)
        return
    end

    vim.cmd("tab split")
    local target = api.nvim_get_current_win()
    local session = {
        buf = buf,
        tab = api.nvim_get_current_tabpage(),
        target = target,
        ours = ours,
        theirs = theirs,
        original = buf,
        windows = { [target] = current },
        pairs = {},
        documents = { target },
        toplines = {},
        commands = {},
        options = {},
    }
    sessions[buf] = session
    local opened, err = pcall(function()
        for _, name in ipairs({ "diff", "scrollbind", "cursorbind", "wrap", "foldenable", "winfixwidth" }) do
            session.options[name] = vim.wo[target][name]
            vim.wo[target][name] = false
        end
        for _, name in ipairs({ "number", "relativenumber", "statuscolumn" }) do
            session.options[name] = vim.wo[target][name]
            vim.wo[target][name] = name == "statuscolumn" and "" or false
        end
        if merge or vim.wo[target].winbar == "" then
            session.options.winbar = vim.wo[target].winbar
            vim.wo[target].winbar = merge and " Result" or " Worktree"
        end
        if merge then
            session.buf = drafts[buf]
            if not session.buf or not api.nvim_buf_is_loaded(session.buf) then
                session.buf = scratch()
                draft.open(session.buf, buf, marker_width)
                vim.b[session.buf].ribbon_original = buf
                drafts[buf] = session.buf
            end
            sessions[session.buf] = session
            api.nvim_win_set_buf(target, session.buf)
            session.windows[target] = session.buf
        end
        local left = reference(session, ours, "left", merge and " Ours" or " HEAD")
        table.insert(session.documents, left)
        pair(session, left, target, "left")
        if merge then
            local right = reference(session, theirs, "right", " Theirs")
            table.insert(session.documents, right)
            pair(session, target, right, "right")
        end
        vim.cmd.wincmd("=")
        sync_scroll(session)
        watch(session)
        if not merge then
            stage_command(session, entry)
        end
        refresh(session)
    end)
    if not opened then
        close(session)
        if api.nvim_win_is_valid(target) then
            api.nvim_win_close(target, false)
        end
        vim.notify(err, vim.log.levels.ERROR)
    end
end

return M
