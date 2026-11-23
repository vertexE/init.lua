local M = {}
local cache = {}

M.get = function(root)
    return cache[root] and cache[root].status
end

-- Callers own refresh timing; every read and redraw uses this repo cache.
M.refresh = function(cwd, callback)
    local function git(args, done)
        local cmd = { "git", "--no-optional-locks" }
        vim.list_extend(cmd, args)
        vim.system(cmd, { cwd = cwd }, vim.schedule_wrap(done))
    end
    git({ "rev-parse", "--show-toplevel" }, function(result)
        if result.code ~= 0 then
            callback(nil, { files = {}, message = "Not a Git repository" })
            return
        end
        local root = result.stdout:gsub("\n$", "")
        local entry = cache[root] or { callbacks = {} }
        cache[root] = entry
        table.insert(entry.callbacks, callback)
        if entry.reading then
            entry.rerun = true
            return
        end
        entry.reading = true
        cwd = root
        local function finish(status)
            if entry.rerun then
                entry.rerun, entry.reading = false, false
                M.refresh(cwd, function() end)
                return
            end
            entry.status = status
            entry.reading = false
            local callbacks = entry.callbacks
            entry.callbacks = {}
            for _, done in ipairs(callbacks) do
                done(root, status)
            end
        end
        git({ "status", "--porcelain=v2", "-z", "--branch", "-uall" }, function(status_result)
            if status_result.code ~= 0 then
                finish({ files = {}, message = "Status unavailable" })
                return
            end
            local status = require("vcs.git_parse").parse_git_status(status_result.stdout)
            local base = status.oid == "(initial)" and "4b825dc642cb6eb9a060e54bf8d69288fbee4904" or "HEAD"
            git({ "diff", "--no-ext-diff", "--no-textconv", "--numstat", "-z", base, "--" }, function(diff)
                if diff.code == 0 then
                    status.added, status.deleted = 0, 0
                    -- Rename records contain extra NUL fields; only tab-delimited stats count.
                    for record in diff.stdout:gmatch("[^%z]+") do
                        local added, deleted = record:match("^(%d+)\t(%d+)\t")
                        status.added = status.added + (tonumber(added) or 0)
                        status.deleted = status.deleted + (tonumber(deleted) or 0)
                    end
                end
                finish(status)
            end)
        end)
    end)
end

return M
