local M = {}

local common = require("vcs.git_common")

--- @type table<string, string>
local enterprise_hosted = {
    --- "dir-name" = "https://github.enterprise.domain.com/ORG/REPO/pull/%s"
}

M.file = function()
    local this_dir_abs = vim.fn.getcwd()
    local this_dir = vim.fn.fnamemodify(this_dir_abs, ":t")
    for dir, domain in pairs(enterprise_hosted) do
        if this_dir == dir then
            local file_name = vim.fn.expand("%:.")
            vim.system({ "bash", "-c", string.format("GH_HOST=%s", domain), "gh", "browse", file_name })
            return
        end
    end

    local file_name = vim.fn.expand("%:.")
    vim.system({ "gh", "browse", file_name })
end

M.remote_branch = function()
    local remote = common.head_branch_name()
    if remote == "" then
        vim.notify("no upstream set for this branch", vim.log.levels.WARN, {})
        return
    end

    local this_dir_abs = vim.fn.getcwd()
    local this_dir = vim.fn.fnamemodify(this_dir_abs, ":t")
    for dir, domain in pairs(enterprise_hosted) do
        if this_dir == dir then
            vim.system({ "open", string.format(domain, remote) })
            return
        end
    end

    local remote_branch = remote:gsub("origin/", "")
    vim.system({ "gh", "browse", "--branch", remote_branch }):wait()
end

return M
