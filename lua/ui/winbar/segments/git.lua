local M = {}

local store = require("ui.winbar.store")
--- we only update drift every 30 seconds
local DRIFT_CACHE_UPDATE_TIME = 30000
local cache = {
    branch = nil,
    drift = { origin = 0, head = 0 }, -- from
}
local valid = {
    branch = false,
    drift = false,
}

local fetch = function()
    vim.system({ "git", "fetch" })
end

--- fetches the drift between this branch and origin
--- @return string
local drift = function()
    if cache.branch == "(unknown)" or not cache.branch then
        return ""
    end

    if not valid.drift then
        vim.system(
            { "git", "rev-list", "--count", string.format("HEAD..origin/%s", cache.branch) },
            { text = true },
            function(out)
                if out.stdout and out.stdout ~= "" then
                    cache.drift.origin = tonumber(vim.trim(out.stdout))
                end
                valid.drift = true
            end
        )
        vim.system(
            { "git", "rev-list", "--count", string.format("origin/%s..HEAD", cache.branch) },
            { text = true },
            function(out)
                if out.stdout and out.stdout ~= "" then
                    cache.drift.head = tonumber(vim.trim(out.stdout))
                end
                valid.drift = true
            end
        )
    end

    return ""
        .. (cache.drift.head == 0 and "" or string.format(" [%d] ", cache.drift.head))
        .. (cache.drift.origin == 0 and "" or string.format(" [%d] ", cache.drift.origin))
end

local branch = function()
    if cache.branch and valid.branch then
        return "  " .. cache.branch
    end

    vim.system({ "git", "branch", "--show-current" }, { text = true }, function(out)
        if out.stdout and out.stdout ~= "" then
            cache.branch = string.gsub(out.stdout, "%s+", "")
        else
            cache.branch = "(unknown)"
        end
        valid.branch = true
    end)

    return cache.branch and ("  " .. cache.branch) or ""
end

M.setup = function()
    store.register_segment({
        name = "git",
        split = false,
        focused = function()
            return { { branch, "MiniIconsPurple" }, { drift, "Comment" } }
        end,
        default = function()
            return { { branch, "MiniIconsPurple" }, { drift, "Comment" } }
        end,
    })

    local group = vim.api.nvim_create_augroup("winbar.git.refresh", { clear = true })

    vim.api.nvim_create_autocmd({ "VimEnter" }, {
        group = group,
        callback = vim.schedule_wrap(function()
            -- ensure the drift is up to date
            fetch()
        end),
    })

    vim.api.nvim_create_autocmd({ "VimEnter", "FocusGained", "BufEnter", "BufLeave" }, {
        group = group,
        callback = vim.schedule_wrap(function()
            valid.branch = false
            valid.drift = false
        end),
    })

    vim.api.nvim_create_autocmd("User", {
        pattern = "MiniGitCommandDone",
        group = group,
        callback = vim.schedule_wrap(function()
            valid.branch = false
            valid.drift = false
        end),
    })

    local timer = vim.uv.new_timer()
    timer:start(
        DRIFT_CACHE_UPDATE_TIME,
        DRIFT_CACHE_UPDATE_TIME,
        vim.schedule_wrap(function()
            valid.drift = false
        end)
    )
end

return M
