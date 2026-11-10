local menu = require("ui.menu")
local M = {}
local syncing = {}

local function file_history()
    if vim.fn.filereadable(vim.api.nvim_buf_get_name(0)) ~= 1 then
        vim.notify("File history needs a saved file", vim.log.levels.WARN)
        return
    end
    vim.cmd("CodeDiff history %")
end

local function stage_file()
    local path = vim.api.nvim_buf_get_name(0)
    if path == "" or vim.bo.buftype ~= "" then
        vim.notify("Stage needs a file buffer", vim.log.levels.WARN)
        return
    end

    local cmd = { "git", "--literal-pathspecs", "add", "--", path }
    local on_exit = vim.schedule_wrap(function(result)
        if result.code == 0 then
            vim.notify("Staged " .. vim.fs.basename(path))
        else
            vim.notify(vim.trim(result.stderr), vim.log.levels.ERROR)
        end
    end)
    local ok, err = pcall(vim.system, cmd, { cwd = vim.fs.dirname(path), text = true }, on_exit)
    if not ok then
        vim.notify("git add failed\n" .. err, vim.log.levels.ERROR)
    end
end

local function git_root()
    local git = require("snacks").git
    local cwd = git.get_root() or git.get_root(vim.fn.getcwd())
    if not cwd then
        vim.notify("No Git repository found", vim.log.levels.WARN)
    end
    return cwd
end

local function sync()
    local cwd = git_root()
    if not cwd then
        return
    end
    if syncing[cwd] then
        vim.notify("Git sync already running", vim.log.levels.INFO)
        return
    end

    local function run(step)
        local on_exit = vim.schedule_wrap(function(result)
            if step == "fetch" and result.code == 0 then
                run("pull")
                return
            end

            syncing[cwd] = nil
            if step == "pull" then
                vim.cmd.checktime()
            end
            if result.code == 0 then
                vim.notify("Git sync complete")
            else
                local output = vim.trim(result.stderr ~= "" and result.stderr or result.stdout)
                vim.notify("git " .. step .. " failed\n" .. output, vim.log.levels.ERROR)
            end
        end)
        local ok, err = pcall(vim.system, { "git", step }, { cwd = cwd, text = true }, on_exit)
        if not ok then
            syncing[cwd] = nil
            vim.notify("git " .. step .. " failed\n" .. err, vim.log.levels.ERROR)
        end
    end

    syncing[cwd] = true
    run("fetch")
end

local function git_refs()
    local cwd = git_root()
    if not cwd then
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
        title = "Git",
        min_width = 40,
        items = {
            {
                label = "Log",
                icon = "",
                keymap = ",l",
                on_select = function()
                    vim.cmd("Git log --pretty=oneline")
                end,
            },
            {
                label = "Diff",
                icon = "",
                keymap = ",d",
                on_select = function()
                    vim.cmd("CodeDiff")
                end,
            },
            { label = "File History", icon = "", keymap = ",h", on_select = file_history },
            {
                label = "Compare Refs",
                icon = "",
                keymap = ",c",
                divider = true,
                children = {
                    {
                        label = "Compare Current Branch",
                        icon = "",
                        keymap = ",h",
                        on_select = function()
                            compare_refs("HEAD")
                        end,
                    },
                    {
                        label = "Compare Two Refs",
                        icon = "",
                        keymap = ",t",
                        on_select = function()
                            compare_refs()
                        end,
                    },
                },
            },
            { label = "Status", icon = "", keymap = ",s", on_select = require("vcs.git_tray").status_tray },
            { label = "Stage", icon = "", keymap = ",a", on_select = stage_file },
            { label = "Sync", icon = "", keymap = ",y", on_select = sync },
            {
                label = "Branches",
                icon = "",
                keymap = ",b",
                on_select = function()
                    require("snacks").picker.git_branches()
                end,
            },
            {
                label = "Stash",
                icon = "",
                keymap = ",t",
                divider = true,
                children = {
                    {
                        label = "Browse & Apply",
                        icon = "",
                        keymap = ",a",
                        on_select = function()
                            require("snacks").picker.git_stash()
                        end,
                    },
                    { label = "Browse & Pop", icon = "", keymap = ",p", on_select = pop_stash },
                },
            },
            {
                label = "File Blame",
                icon = "",
                keymap = ",f",
                on_select = function()
                    vim.cmd("Gitsigns blame")
                end,
            },
        },
    })
end

return M
