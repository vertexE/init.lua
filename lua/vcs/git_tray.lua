local M = {}

local api = vim.api
local floats = require("ui.floats")
local confirm = require("ui.confirm")
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
    return view == tray and api.nvim_win_is_valid(view.win) and api.nvim_win_get_buf(view.win) == view.buf
end

local function hide_tray_cursor(buf)
    api.nvim_set_hl(0, "GitTrayHiddenCursor", { blend = 100, nocombine = true })
    local saved_cursor
    local function hide()
        if saved_cursor == nil then
            saved_cursor = vim.o.guicursor
            local prefix = saved_cursor == "" and "" or saved_cursor .. ","
            vim.o.guicursor = prefix .. "n-v-ve:GitTrayHiddenCursor"
        end
    end
    local function restore()
        if saved_cursor ~= nil then
            vim.o.guicursor = saved_cursor
            saved_cursor = nil
        end
    end
    api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, { buffer = buf, callback = hide })
    api.nvim_create_autocmd({ "WinLeave", "BufLeave", "BufWipeout" }, { buffer = buf, callback = restore })
    hide()
end

local function render(view, status)
    local cursor = api.nvim_win_get_cursor(view.win)[1]
    local selected = view.rows[cursor]
    local ahead, behind = (status.ab or ""):match("^%+(%d+) %-(%d+)$")
    local summary = (ahead and ("↑ " .. ahead .. " push  ↓ " .. behind .. " pull"))
        or (status.upstream and "Upstream unavailable")
        or "No upstream"
    local heading = status.message and "Git status" or (status.head or "Git status") .. "  " .. summary
    local files = {}
    for path, file in pairs(status.files) do
        local display_path = path
        if file.index == "." and file.worktree == "?" and status.folders then
            for slash in path:gmatch("()/") do
                local folder = path:sub(1, slash)
                if status.folders[folder] then
                    display_path = folder
                    break
                end
            end
        end
        files[display_path] = file
    end
    local paths = vim.tbl_keys(files)
    table.sort(paths)
    local icons = require("mini.icons")
    local lines = { { { heading, "Title" } } }
    local rows = {}
    for _, path in ipairs(paths) do
        local file = files[path]
        local dir, name = path:match("^(.*/)([^/]+/?)$")
        local icon, hl = icons.get(path:sub(-1) == "/" and "directory" or "file", path)
        table.insert(lines, {
            { file.index, file.index == "." and "Comment" or "DiffAdd" },
            { file.worktree, file.worktree == "." and "Comment" or "DiffChange" },
            { "  " .. icon .. " ", hl },
            { vim.fn.strtrans(name or path) },
            { dir and ("  " .. vim.fn.strtrans(dir)) or "", "Comment" },
        })
        rows[#lines] = path
        if selected == path then
            cursor = #lines
        end
    end
    if #lines == 1 then
        table.insert(lines, { { status.message or "No changes", "Comment" } })
    end

    vim.bo[view.buf].modifiable = true
    api.nvim_buf_clear_namespace(view.buf, namespace, 0, -1)
    extmarks.write_vlines_as_content(view.buf, namespace, lines)
    vim.bo[view.buf].modifiable = false
    view.rows = rows
    api.nvim_win_set_cursor(view.win, { math.max(2, math.min(cursor, #lines)), 0 })
end

local function read_status(root, callback)
    local args = { "--no-optional-locks", "status", "--porcelain=v2", "-z", "--branch", "--ahead-behind", "-unormal" }
    git(root, args, function(result)
        if result.code ~= 0 then
            callback(nil, result.stderr)
            return
        end
        local status = parse_status(result.stdout)
        local folders = {}
        for path, file in pairs(status.files) do
            if file.worktree == "?" and path:sub(-1) == "/" then
                folders[path] = true
            end
        end
        if next(folders) == nil then
            callback(status)
            return
        end

        -- Keep exact file markers for optimistic staging and reconciliation.
        args[#args] = "-uall"
        git(root, args, function(expanded)
            if expanded.code ~= 0 then
                callback(nil, expanded.stderr)
                return
            end
            local detailed = parse_status(expanded.stdout)
            detailed.folders = folders
            callback(detailed)
        end)
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
            if path:sub(-1) == "/" then
                for child, file in pairs(view.status.files) do
                    if vim.startswith(child, path) and file.index == "." and file.worktree == "?" then
                        files[child] = file
                    end
                end
            else
                files[path] = view.status.files[path]
            end
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

local function discard(view)
    if not view.status or view.reading or pending[view.root] then
        return
    end
    local path = view.rows[api.nvim_win_get_cursor(view.win)[1]]
    if not path then
        return
    end
    local folder = path:sub(-1) == "/"
    local file = view.status.files[path]
    local untracked = folder or (file.index == "." and file.worktree == "?")
    if file and file.submodule then
        notify("Discard submodule changes from inside the submodule", vim.log.levels.WARN)
        return
    end
    local original = file and (file.index == "R" or file.worktree == "R") and file.original
    local label = vim.fn.strtrans(path)
    if original then
        label = vim.fn.strtrans(original) .. " → " .. label
    end
    local action = untracked and "Delete untracked " or "Discard staged and unstaged changes for "
    confirm.open(action .. label .. "?", function(accepted)
        if not accepted or not active(view) or view.reading or pending[view.root] then
            return
        end
        pending[view.root] = true
        local function finish(result)
            pending[view.root] = nil
            if tray and tray.root == view.root and active(tray) then
                refresh(tray)
            end
            if result.code ~= 0 then
                notify(result.stderr, vim.log.levels.ERROR)
            end
        end
        read_status(view.root, function(status, err)
            if not status then
                finish({ code = 1, stderr = err })
                return
            end
            local unchanged = folder and status.folders and status.folders[path]
                or (not folder and vim.deep_equal(file, status.files[path]))
            if not unchanged then
                finish({ code = 1, stderr = "Git status changed. Review the refreshed row before discarding." })
                return
            end
            if untracked then
                git(view.root, { "clean", "-fd", "--", path }, finish)
                return
            end
            local disk = vim.uv.fs_lstat(view.root .. "/" .. path)
            local original_disk = original and vim.uv.fs_lstat(view.root .. "/" .. original)
            if (disk and disk.type == "directory")
                or (original and (status.files[original] or original_disk))
            then
                finish({ code = 1, stderr = "Discard would overwrite a separate file or directory." })
                return
            end
            local function restore(source)
                local args = { "restore", "--source=" .. source, "--staged", "--worktree", "--", path }
                if original then
                    table.insert(args, original)
                end
                git(view.root, args, finish)
            end
            if status.oid == "(initial)" then
                git(view.root, { "hash-object", "-t", "tree", "--stdin" }, function(result)
                    if result.code == 0 then
                        restore(vim.trim(result.stdout))
                    else
                        finish(result)
                    end
                end, "")
            else
                restore("HEAD")
            end
        end)
    end)
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
        return
    end
    local result = vim.system({ "git", "rev-parse", "--show-toplevel" }):wait()
    if result.code ~= 0 then
        notify(result.stderr, vim.log.levels.ERROR)
        return
    end
    local origin = api.nvim_get_current_win()
    local bufnr = api.nvim_create_buf(false, true)
    vim.bo[bufnr].bufhidden = "wipe"
    local win = api.nvim_open_win(bufnr, true, {
        split = "left",
        win = -1,
        width = math.floor(vim.o.columns / 4),
    })
    vim.wo[win].wrap = false
    vim.wo[win].number = false
    vim.wo[win].relativenumber = false
    vim.wo[win].signcolumn = "no"
    vim.wo[win].foldcolumn = "0"
    floats.highlight_selection(win)
    hide_tray_cursor(bufnr)
    local view = { buf = bufnr, win = win, root = result.stdout:gsub("\n$", ""), rows = {} }
    local previous = tray
    tray = view
    if previous and api.nvim_win_is_valid(previous.win) and api.nvim_win_get_buf(previous.win) == previous.buf then
        api.nvim_win_close(previous.win, false)
    end
    vim.b[bufnr].minicursorword_disable = true
    local function map(mode, key, action)
        vim.keymap.set(mode, key, action, { buffer = bufnr })
    end
    map({ "n", "x" }, "<Tab>", function()
        toggle(view)
    end)
    vim.keymap.set("n", "dd", function()
        discard(view)
    end, { buffer = bufnr, desc = "Discard changes" })
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
        if api.nvim_win_is_valid(origin)
            and api.nvim_win_get_tabpage(origin) == api.nvim_win_get_tabpage(win)
            and api.nvim_win_get_config(origin).relative == ""
        then
            api.nvim_set_current_win(origin)
        else
            vim.cmd.wincmd("l")
            if api.nvim_get_current_win() == win then
                vim.cmd("rightbelow vsplit")
            end
        end
        vim.cmd.edit({ args = { path }, magic = { file = false, bar = false }, mods = { hide = true } })
    end)
    map("n", "q", function()
        api.nvim_buf_delete(bufnr, { force = true })
    end)
    vim.keymap.set("n", ",r", function()
        refresh(view)
    end, { buffer = bufnr, desc = "Refresh Git status" })
    render(view, { files = {}, message = pending[view.root] and "Updating index…" or "Loading…" })
    refresh(view)
end

return M
