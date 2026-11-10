local M = {}

local api = vim.api
local floats = require("ui.floats")
local extmarks = require("ui.extmarks")
local parse_status = require("vcs.git_parse").parse_git_status
local namespace = api.nvim_create_namespace("user.git.tray")
local pending = {}
local tray

local function notify(message, level)
    vim.notify(vim.trim(message), level, { title = "Git status" })
end

local function git(root, args, callback, stdin)
    local cmd = { "git", "--literal-pathspecs" }
    vim.list_extend(cmd, args)
    local ok, err = pcall(vim.system, cmd, { cwd = root, stdin = stdin }, vim.schedule_wrap(callback))
    if not ok then
        callback({ code = -1, stderr = tostring(err) })
    end
end

local function active(view)
    return view == tray and api.nvim_win_is_valid(view.win)
end

local function dimensions(width, height)
    return math.min(width, vim.o.columns - 2), math.min(height, math.max(1, vim.o.lines - vim.o.cmdheight - 2))
end

local function fit(text, width)
    if vim.fn.strdisplaywidth(text) > width then
        local limit = width - vim.fn.strdisplaywidth("…")
        if limit < 0 then
            return string.rep(" ", width)
        end
        text = vim.fn.strcharpart(text, 0, limit)
        while vim.fn.strdisplaywidth(text) > limit do
            text = vim.fn.strcharpart(text, 0, vim.fn.strchars(text) - 1)
        end
        text = text .. "…"
    end
    return text .. string.rep(" ", width - vim.fn.strdisplaywidth(text))
end

local function render(view, status)
    local cursor = api.nvim_win_get_cursor(view.win)[1]
    local selected = view.rows[cursor]
    local ahead, behind = (status.ab or ""):match("^%+(%d+) %-(%d+)$")
    local summary = (ahead and ("↑ " .. ahead .. " push  ↓ " .. behind .. " pull"))
        or (status.upstream and "Upstream unavailable")
        or "No upstream"
    local heading = status.message and "Git status" or (status.head or "Git status") .. "  " .. summary
    local paths = vim.tbl_keys(status.files)
    table.sort(paths)
    local icons = require("mini.icons")
    local labels = {}
    local columns = " │ Index │ Worktree"
    local column_width = vim.fn.strdisplaywidth(columns)
    local width = math.max(60, vim.fn.strdisplaywidth(heading))
    for _, path in ipairs(paths) do
        local dir, name = path:match("^(.*/)([^/]+)$")
        local icon, hl = icons.get("file", path)
        local label = {
            icon = icon .. " ",
            hl = hl,
            dir = vim.fn.strtrans(dir or ""),
            name = vim.fn.strtrans(name or path),
        }
        labels[path] = label
        width = math.max(width, vim.fn.strdisplaywidth(label.icon .. label.dir .. label.name) + column_width + 1)
    end

    local height
    width, height = dimensions(width, math.max(3, #paths + 2))
    api.nvim_win_set_config(view.win, {
        relative = "editor",
        width = width,
        height = height,
        row = math.floor((vim.o.lines - height - 2) / 2),
        col = math.floor((vim.o.columns - width - 2) / 2),
    })

    local path_width = math.max(2, width - column_width)
    local lines = {
        { { fit(heading, width), "Title" } },
        { { fit("Path", path_width) .. columns, "Comment" } },
    }
    local rows = {}
    for _, path in ipairs(paths) do
        local file = status.files[path]
        local label = labels[path]
        local icon = vim.fn.strdisplaywidth(label.icon) < path_width and label.icon or ""
        local available = path_width - vim.fn.strdisplaywidth(icon)
        local name_width = vim.fn.strdisplaywidth(label.name)
        local dir_width = math.min(vim.fn.strdisplaywidth(label.dir), math.max(0, available - name_width))
        table.insert(lines, {
            { icon, label.hl },
            { fit(label.dir, dir_width), "Comment" },
            { fit(label.name, available - dir_width) },
            { " │   ", "Comment" },
            { file.index, file.index == "." and "Comment" or "DiffAdd" },
            { "   │    ", "Comment" },
            { file.worktree, file.worktree == "." and "Comment" or "DiffChange" },
        })
        rows[#lines] = path
        if selected == path then
            cursor = #lines
        end
    end
    if #lines == 2 then
        table.insert(lines, { { status.message or "No changes", "Comment" } })
    end

    vim.bo[view.buf].modifiable = true
    api.nvim_buf_clear_namespace(view.buf, namespace, 0, -1)
    extmarks.write_vlines_as_content(view.buf, namespace, lines)
    vim.bo[view.buf].modifiable = false
    view.rows = rows
    api.nvim_win_set_cursor(view.win, { math.max(3, math.min(cursor, #lines)), 0 })
end

local function read_status(root, callback)
    local args = { "--no-optional-locks", "status", "--porcelain=v2", "-z", "--branch", "--ahead-behind", "-uall" }
    git(root, args, function(result)
        if result.code ~= 0 then
            callback(nil, result.stderr)
        else
            callback(parse_status(result.stdout))
        end
    end)
end

local function refresh(view)
    if view.reading or pending[view.root] then
        return
    end
    view.reading = true
    read_status(view.root, function(status, err)
        view.reading = false
        if not active(view) then
            return
        end
        view.status = status
        render(view, status or { files = {}, message = "Status unavailable" })
        if err then
            notify(err, vim.log.levels.ERROR)
        end
    end)
end

local function expected_files(status, paths, stage)
    local expected = vim.deepcopy(status)
    local touched = {}
    local function set(path, index, worktree, original)
        touched[path] = true
        expected.files[path] = (index ~= "." or worktree ~= ".")
            and { index = index, worktree = worktree, original = original }
            or nil
    end
    for _, path in ipairs(paths) do
        local file = status.files[path]
        local index, worktree = file.index, file.worktree
        touched[path] = true
        if file.original then
            touched[file.original] = true
        end
        if stage then
            if file.original and worktree == "D" then
                set(path, ".", ".")
                if index == "R" then
                    set(file.original, "D", ".")
                end
            elseif worktree == "D" or file.worktree_mode == "000000" and worktree ~= "?" then
                set(path, file.head_mode == "000000" and "." or "D", ".")
            elseif file.original and index ~= "." then
                set(path, index, ".", file.original)
            elseif not file.submodule or file.submodule:sub(2, 2) == "C" then
                local type_changed = file.worktree_mode and worktree ~= "?"
                    and file.head_mode:sub(1, 2) ~= file.worktree_mode:sub(1, 2)
                local mark = file.head_mode == "000000" and "A" or type_changed and "T" or "M"
                local submodule_dirty = file.submodule and file.submodule:sub(3) ~= ".."
                set(path, mark, submodule_dirty and "M" or ".")
            end
        elseif file.original then
            set(path, ".", "?")
            if index == "R" then
                set(file.original, ".", "D")
            end
        else
            local mark = index == "A" and "?" or worktree == "?" and "M" or index
            set(path, ".", mark)
        end
    end
    return expected, touched
end

local function toggle(view)
    if not view.status or view.reading or pending[view.root] then
        return
    end
    local first = api.nvim_win_get_cursor(view.win)[1]
    local last = first
    if vim.fn.mode():match("^[vV\22]") then
        local anchor = vim.fn.line("v")
        first, last = math.min(first, anchor), math.max(first, anchor)
        local esc = api.nvim_replace_termcodes("<Esc>", true, false, true)
        api.nvim_feedkeys(esc, "nx", false)
    end
    local files = {}
    for line = first, last do
        local path = view.rows[line]
        if path then
            files[path] = view.status.files[path]
        end
    end
    if next(files) == nil then
        return
    end
    local stage = false
    for _, file in pairs(files) do
        stage = stage or file.worktree ~= "." or file.conflict
    end
    local paths, pathspecs = {}, {}
    for path, file in pairs(files) do
        if not stage or file.worktree ~= "." or file.conflict then
            table.insert(paths, path)
            pathspecs[path] = true
            if file.original and (file.index == "." or not stage) then
                pathspecs[file.original] = true
            end
        end
    end
    local expected, touched = expected_files(view.status, paths, stage)
    pending[view.root] = true
    render(view, expected)
    local args = stage and { "add", "-A" } or { "reset", "-q" }
    vim.list_extend(args, { "--pathspec-from-file=-", "--pathspec-file-nul" })
    git(view.root, args, function(result)
        read_status(view.root, function(status, err)
            pending[view.root] = nil
            if tray and tray.root == view.root and active(tray) then
                tray.status = status
                render(tray, status or { files = {}, message = "Status unavailable" })
            end
            if result.code ~= 0 then
                notify(result.stderr, vim.log.levels.ERROR)
            end
            if err then
                notify(err, vim.log.levels.ERROR)
            elseif result.code == 0 then
                for path in pairs(touched) do
                    local actual = status.files[path] or {}
                    local predicted = expected.files[path] or {}
                    if actual.index ~= predicted.index
                        or actual.worktree ~= predicted.worktree
                        or actual.original ~= predicted.original
                    then
                        local message = "Git status differed from staging preview for " .. vim.fn.strtrans(path)
                        notify(message, vim.log.levels.WARN)
                        break
                    end
                end
            end
        end)
    end, table.concat(vim.tbl_keys(pathspecs), "\0") .. "\0")
end

local function commit(view)
    if view.reading or pending[view.root] then
        return
    end
    vim.ui.input({ prompt = "Commit message: " }, function(message)
        if not message or vim.trim(message) == "" or not active(view) or view.reading or pending[view.root] then
            return
        end
        pending[view.root] = true
        git(view.root, { "commit", "-m", message }, function(result)
            pending[view.root] = nil
            if tray and tray.root == view.root and active(tray) then
                refresh(tray)
            end
            if result.code == 0 then
                notify("Committed staged changes", vim.log.levels.INFO)
            else
                local output = result.stderr and result.stderr ~= "" and result.stderr or result.stdout
                notify(output or "git commit failed", vim.log.levels.ERROR)
            end
        end)
    end)
end

M.status_tray = function()
    if tray and active(tray) and api.nvim_win_get_tabpage(tray.win) == api.nvim_get_current_tabpage() then
        api.nvim_set_current_win(tray.win)
        refresh(tray)
        return
    end
    local result = vim.system({ "git", "rev-parse", "--show-toplevel" }):wait()
    if result.code ~= 0 then
        notify(result.stderr, vim.log.levels.ERROR)
        return
    end
    local origin = api.nvim_get_current_win()
    local width, height = dimensions(60, 3)
    local bufnr, win = floats.open({
        bufnr = api.nvim_create_buf(false, true),
        title = " Git status ",
        width = width,
        height = height,
        bo = { bufhidden = "wipe" },
        wo = { cursorline = true, wrap = false, signcolumn = "no", foldcolumn = "0" },
    })
    local view = { buf = bufnr, win = win, root = result.stdout:gsub("\n$", ""), rows = {} }
    local previous = tray
    tray = view
    if previous and api.nvim_win_is_valid(previous.win) then
        api.nvim_win_close(previous.win, false)
    end
    vim.b[bufnr].minicursorword_disable = true
    local function map(mode, key, action)
        vim.keymap.set(mode, key, action, { buffer = bufnr })
    end
    map({ "n", "x" }, "<Tab>", function()
        toggle(view)
    end)
    vim.keymap.set("n", ",c", function()
        commit(view)
    end, { buffer = bufnr, desc = "Commit staged changes" })
    map("n", "<CR>", function()
        local selected = view.rows[api.nvim_win_get_cursor(win)[1]]
        if not selected then
            return
        end
        local path = view.root .. "/" .. selected
        if not vim.uv.fs_lstat(path) then
            notify("File no longer exists: " .. vim.fn.strtrans(selected), vim.log.levels.WARN)
            return
        end
        api.nvim_win_close(win, false)
        if api.nvim_win_is_valid(origin) then
            api.nvim_set_current_win(origin)
        end
        vim.cmd.edit({ args = { path }, magic = { file = false, bar = false }, mods = { hide = true } })
    end)
    map("n", "<Esc>", function()
        api.nvim_win_close(win, false)
    end)
    render(view, { files = {}, message = pending[view.root] and "Updating index…" or "Loading…" })
    refresh(view)
end

return M
