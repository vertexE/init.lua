local ids = require("ids")
local git = require("vcs.git_common")
local resources = require("assistant.resources")
local rules = require("assistant.rules")
local PromptBuilder = require("assistant.prompt_builder")
local agents = require("assistant.agents")

local M = {}

local CACHE_DIR = ".agent-cache"

--- @class WorktreeTask
--- @field id string
--- @field request string
--- @field worktree string
--- @field status "running"|"done"|"failed"
--- @field patch string|nil
--- @field error string|nil

--- @type WorktreeTask[]
local tasks = {}

local provider_strategy = function()
    return resources.agent_name() == "Codex" and agents.codex or agents.claude
end

local first_error = function(result)
    return (result.stderr and #result.stderr > 0) and result.stderr or result.stdout or "agent failed"
end

local fail = function(task, err)
    task.status = "failed"
    task.error = err
    vim.notify(string.format('(assistant): worktree task failed: "%s"', task.request), vim.log.levels.ERROR)
end

local mkdir = function(path)
    if not vim.fn.isdirectory(path) then
        vim.fn.mkdir(path, "p")
    end
end

--- @return WorktreeTask[]
M.list = function()
    return tasks
end

--- @param request string
--- @param ctx prompt.context
M.add = function(request, ctx)
    local ok_root, root = git.git_absolute_root_path()
    if not ok_root then
        vim.notify(root, vim.log.levels.ERROR)
        return
    end

    local id = ids.uuidv4()
    local cache = vim.fs.joinpath(root, CACHE_DIR)
    local worktrees_dir = vim.fs.joinpath(cache, "worktrees")
    local patches_dir = vim.fs.joinpath(cache, "patches")
    local worktree = vim.fs.joinpath(worktrees_dir, id)
    local patch = vim.fs.joinpath(patches_dir, id .. ".patch")

    --- @type WorktreeTask
    local task = {
        id = id,
        request = request,
        worktree = worktree,
        status = "running",
        patch = nil,
    }
    table.insert(tasks, task)

    local clean = git.git_diff_quiet({ running_dir = root })
    if not clean then
        task.status = "failed"
        task.error = "local changes found"
        vim.notify("(assistant): cannot create worktree with local changes", vim.log.levels.WARN)
        return
    end

    mkdir(worktrees_dir)
    mkdir(patches_dir)

    local ok_add, add_err = git.git_worktree_add(worktree, { running_dir = root })
    if not ok_add then
        fail(task, add_err)
        return
    end

    local context = resources.active(ctx.req_bufnr)
    local prompt = PromptBuilder:new()
        :with_permissions({ "write" })
        :with_strategy(provider_strategy())
        :with_exec_dir(worktree)
        :with_rules(rules.worktree(ctx))
        :with_task(request .. "\n" .. context)
        :build()

    prompt:run(function(_)
        local ok_index, index_err = git.git_index_all({ running_dir = worktree })
        if not ok_index then
            fail(task, index_err)
            return
        end

        local ok_patch, patch_err = git.git_diff_head_to_patch(patch, { running_dir = worktree })
        if not ok_patch then
            fail(task, #patch_err > 0 and patch_err or "task completed with no changes")
            return
        end

        task.status = "done"
        task.patch = patch

        local ok_remove, remove_err = git.git_worktree_remove(worktree, { running_dir = root })
        if not ok_remove then
            task.error = remove_err
        end

        vim.notify(string.format('(assistant): worktree task completed: "%s"', task.request), vim.log.levels.INFO)
    end, function(result)
        fail(task, first_error(result))
    end)
end

return M
