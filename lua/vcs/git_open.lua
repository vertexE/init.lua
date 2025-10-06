local M = {}

local common = require("vcs.git_common")

--- @type table<string, string>
local enterprise_hosted = {
    --- "dir-name" = "github-enterprise-domain"
}

M.file = function()
    local buf = vim.api.nvim_get_current_buf()
    local this_dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":h")
    for dir, domain in pairs(enterprise_hosted) do
        if this_dir == dir then
            local file_name = vim.fn.expand("%:.")
            vim.system({ "bash", "-c", string.format("GH_HOST=%s", domain), "gh", "browse", file_name })
        end
    end

    local file_name = vim.fn.expand("%:.")
    vim.system({ "gh", "browse", file_name })
end

M.remote_branch = function()
    local remote = common.remote_branch_name()
    if remote == "no upstream" then
        vim.notify("no upstream set for this branch", vim.log.levels.WARN, {})
        return
    end

    local buf = vim.api.nvim_get_current_buf()
    local this_dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":h")
    for dir, domain in pairs(enterprise_hosted) do
        if this_dir == dir then
            vim.system({ "bash", "-c", string.format("GH_HOST=%s", domain), "gh", "browse", remote }):wait()
        end
    end

    local remote_branch = remote:gsub("origin/", "")
    vim.system({ "gh", "browse", "--branch", remote_branch }):wait()
end

return M
