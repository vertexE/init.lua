local menu = require("ui.menu")
local M = {}

local function file_history()
    if vim.fn.filereadable(vim.api.nvim_buf_get_name(0)) ~= 1 then
        vim.notify("File history needs a saved file", vim.log.levels.WARN)
        return
    end
    vim.cmd("CodeDiff history %")
end

local function git_refs()
    local git = require("snacks").git
    local cwd = git.get_root() or git.get_root(vim.fn.getcwd())
    if not cwd then
        vim.notify("No Git repository found", vim.log.levels.WARN)
        return
    end

    local result = vim.system({
        "git",
        "for-each-ref",
        "--format=%(if)%(symref)%(then)%(else)%(refname)%(end)",
        "refs/heads",
        "refs/remotes",
        "refs/tags",
    }, { cwd = cwd, text = true }):wait()
    if result.code ~= 0 then
        vim.notify(vim.trim(result.stderr), vim.log.levels.ERROR)
        return
    end

    local refs = vim.split(result.stdout, "\n", { trimempty = true })
    if #refs == 0 then
        vim.notify("No branches or tags found", vim.log.levels.INFO)
        return
    end
    return refs
end

local function ref_label(ref)
    return (ref:gsub("^refs/", ""))
end

local function select_ref(refs, prompt, on_choice)
    vim.ui.select(refs, {
        prompt = prompt,
        format_item = ref_label,
    }, function(ref)
        if ref then
            on_choice(ref)
        end
    end)
end

local function compare_refs(target)
    local refs = git_refs()
    if not refs then
        return
    end

    local prompt = target and "Compare with HEAD" or "Pick base ref"
    select_ref(refs, prompt, function(base)
        if target then
            vim.cmd.CodeDiff({ args = { base, target } })
            return
        end

        select_ref(refs, "Pick target ref (base: " .. ref_label(base) .. ")", function(selected)
            vim.cmd.CodeDiff({ args = { base, selected } })
        end)
    end)
end

local function pop_stash()
    require("snacks").picker.git_stash({
        title = "Pop Git Stash",
        confirm = function(picker, item)
            picker:close()
            if not item then
                return
            end

            local cmd = { "git", "stash", "pop", item.stash }
            vim.system(cmd, { cwd = item.cwd, text = true }, vim.schedule_wrap(function(result)
                if result.code == 0 then
                    vim.cmd.checktime()
                    vim.notify("Popped " .. item.stash)
                else
                    vim.notify(vim.trim(result.stderr ~= "" and result.stderr or result.stdout), vim.log.levels.ERROR)
                end
            end))
        end,
    })
end

function M.open()
    return menu.open({
        position = "editor",
        items = {
            {
                label = "Git Log",
                keymap = ",l",
                on_select = function()
                    vim.cmd("Git log --pretty=oneline")
                end,
            },
            {
                label = "Git Diff",
                keymap = ",d",
                on_select = function()
                    vim.cmd("CodeDiff")
                end,
            },
            { label = "Current File History", on_select = file_history },
            {
                label = "Compare Refs",
                divider = true,
                children = {
                    {
                        label = "Compare Current Branch",
                        on_select = function()
                            compare_refs("HEAD")
                        end,
                    },
                    {
                        label = "Compare Two Refs",
                        on_select = function()
                            compare_refs()
                        end,
                    },
                },
            },
            { label = "Git Status", on_select = require("vcs.git_tray").status_tray },
            {
                label = "Git Branches",
                on_select = function()
                    require("snacks").picker.git_branches()
                end,
            },
            {
                label = "Stash",
                divider = true,
                children = {
                    {
                        label = "Browse & Apply",
                        on_select = function()
                            require("snacks").picker.git_stash()
                        end,
                    },
                    { label = "Browse & Pop", on_select = pop_stash },
                },
            },
            {
                label = "File Blame",
                on_select = function()
                    vim.cmd("Gitsigns blame")
                end,
            },
        },
    })
end

return M
