local M = {}

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

return M
