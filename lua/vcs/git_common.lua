local M = {}

local run = function(cmd, opts)
    opts = opts or {}
    local result = vim.system(cmd, { text = true, cwd = opts.running_dir }):wait()
    if result.code == 0 then
        return true, result.stdout or ""
    end

    return false, (result.stderr and #result.stderr > 0) and result.stderr or result.stdout or "git command failed"
end

---@param staged ?boolean whether to look at the staged diff instead
M.git_stats = function(staged)
    local result =
        vim.system(staged and { "git", "diff", "--stat", "--staged" } or { "git", "diff", "--stat" }, { text = true })
            :wait()
    local lines = vim.split(result.stdout or "", "\n", { trimempty = true })
    return (lines[#lines] or ""):gsub("^%s*(.-)%s*$", "%1")
end

M.head_branch_name = function()
    local result = vim.system({ "git", "branch", "--show-current" }, { text = true }):wait()
    local branch = (result.stdout or ""):gsub("%s", "")
    if branch ~= "" then
        return branch
    else
        return ""
    end
end

M.remote_branch_name = function()
    local result = vim.system({ "git", "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}" }, { text = true })
        :wait()
    local remote = (result.stdout or ""):gsub("%s", "")
    if remote ~= "" then
        return remote
    else
        return "no upstream"
    end
end

M.head_commit = function()
    local result = vim.system({ "git", "rev-parse", "HEAD" }, { text = true }):wait()
    return (result.stdout or ""):gsub("%s", "")
end

M.remote_commit = function()
    local result = vim.system({ "git", "rev-parse", "@{u}" }, { text = true }):wait()
    return (result.stdout or ""):gsub("%s", "")
end

M.commit_msg = function(commit_sha)
    local result = vim.system({ "git", "log", "-1", "--pretty=%s", commit_sha }, { text = true }):wait()
    return (result.stdout or ""):gsub("%s+$", "")
end

M.git_root = function()
    local result = vim.system({ "git", "rev-parse", "--show-toplevel" }, { text = true }):wait()
    local git_root = result.stdout:gsub("\n", "")
    local root_name = vim.fn.fnamemodify(git_root, ":t")
    return root_name
end

M.git_absolute_root_path = function()
    local ok, root = run({ "git", "rev-parse", "--show-toplevel" })
    return ok, root:gsub("%s+$", "")
end

M.git_diff_quiet = function(opts)
    return run({ "git", "diff", "--quiet" }, opts)
end

M.git_worktree_add = function(path, opts)
    return run({ "git", "worktree", "add", "--detach", path, "HEAD" }, opts)
end

M.git_index_all = function(opts)
    return run({ "git", "add", "-N", "." }, opts)
end

M.git_diff_head_to_patch = function(patch, opts)
    local ok, diff = run({ "git", "diff", "HEAD" }, opts)
    if not ok then
        return false, diff
    end

    local file = io.open(patch, "w")
    if not file then
        return false, string.format("could not open patch file: %s", patch)
    end

    file:write(diff)
    file:close()
    return #diff > 0, diff
end

M.git_apply = function(patch, opts)
    return run({ "git", "apply", patch }, opts)
end

M.git_worktree_remove = function(path, opts)
    return run({ "git", "worktree", "remove", path }, opts)
end

return M
