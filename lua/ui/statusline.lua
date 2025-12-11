local M = {}

local git_common = require("vcs.git_common")

local FIFO_PIPE_UPDATE_TIME = 3000

local cache = {
    spotify = "No track currently playing",
    tools = {},
}

local valid = {
    spotify = true,
    tools = false,
}

local loading = {
    spotify = false,
}

--- @param vlines table<table<string,string>>
--- @return string
local vlines_to_inline_hl = function(vlines)
    local content = ""
    for _, segment in ipairs(vlines) do
        local s, hl = unpack(segment)
        content = content .. string.format("%%#%s#%s", hl, s)
    end
    return content
end

local spotify = function()
    if valid.spotify then
        return #cache.spotify > 0
                and {
                    { "", "TinyInlineInvDiagnosticVirtualTextInfoNoBg" },
                    { "󰓇  ", "TinyInlineDiagnosticVirtualTextInfo" },
                    { cache.spotify, "TinyInlineDiagnosticVirtualTextInfo" },
                    { "", "TinyInlineInvDiagnosticVirtualTextInfoNoBg" },
                }
            or {}
    end

    -- this is a fifo pipe, will block until read/write pair go through
    if not loading.spotify then
        vim.system({ "cat", "/tmp/fifoplayer-track" }, { text = true }, function(result)
            if #result.stdout > 0 then
                cache.spotify = result.stdout
                valid.spotify = true
                loading.spotify = false
            end
        end)
        loading.spotify = true
    end

    return #cache.spotify > 0
            and {
                { "", "TinyInlineInvDiagnosticVirtualTextInfoNoBg" },
                { "󰓇  ", "TinyInlineDiagnosticVirtualTextInfo" },
                { cache.spotify, "TinyInlineDiagnosticVirtualTextInfo" },
                { "", "TinyInlineInvDiagnosticVirtualTextInfoNoBg" },
            }
        or {}
end

M.spotify = function()
    local segments = spotify()
    return vlines_to_inline_hl(segments)
end

local mode_map = {
    ["n"] = "NORMAL",
    ["no"] = "OP-PENDING",
    ["nov"] = "OP-PENDING",
    ["noV"] = "OP-PENDING",
    ["no\22"] = "OP-PENDING",
    ["niI"] = "NORMAL",
    ["niR"] = "NORMAL",
    ["niV"] = "NORMAL",
    ["nt"] = "NORMAL",
    ["ntT"] = "NORMAL",
    ["v"] = "VISUAL",
    ["vs"] = "VISUAL",
    ["V"] = "S-VISUAL",
    ["Vs"] = "VISUAL",
    ["\22"] = "VISUAL",
    ["\22s"] = "VISUAL",
    ["s"] = "SELECT",
    ["S"] = "SELECT",
    ["\19"] = "SELECT",
    ["i"] = "INSERT",
    ["ic"] = "INSERT",
    ["ix"] = "INSERT",
    ["R"] = "REPLACE",
    ["Rc"] = "REPLACE",
    ["Rx"] = "REPLACE",
    ["Rv"] = "VIRT REPLACE",
    ["Rvc"] = "VIRT REPLACE",
    ["Rvx"] = "VIRT REPLACE",
    ["c"] = "COMMAND",
    ["cv"] = "VIM EX",
    ["ce"] = "EX",
    ["r"] = "PROMPT",
    ["rm"] = "MORE",
    ["r?"] = "CONFIRM",
    ["!"] = "SHELL",
    ["t"] = "TERMINAL",
}

M.mode = function()
    -- Get the respective string to display.
    local mode = mode_map[vim.api.nvim_get_mode().mode] or "UNKNOWN"

    -- -- Set the highlight group.
    local hl = "Other"
    if mode:find("NORMAL") then
        hl = "Normal"
    elseif mode:find("REPLACE") then
        hl = "Replace"
    elseif mode:find("VISUAL") then
        hl = "Visual"
    elseif mode:find("INSERT") or mode:find("SELECT") then
        hl = "Insert"
    elseif mode:find("COMMAND") or mode:find("TERMINAL") or mode:find("EX") then
        hl = "Command"
    elseif mode:find("PENDING") then
        hl = "Pending"
    end

    local status, dap = pcall(require, "dap")
    if status and dap.session() then
        return string.format("%%#CommandMode#▌ %s", " DEBUG")
    end

    return string.format("%%#%sMode#▌ %s ", hl, mode)
end

M.tools = function()
    if valid.tools then
        return vlines_to_inline_hl(cache.tools)
    end

    local clients = vim.lsp.get_clients({ bufnr = 0 })
    local vlines = {
        { "", "TinyInlineInvDiagnosticVirtualTextInfoNoBg" },
        { "", "TinyInlineDiagnosticVirtualTextInfo" },
    }
    for _, client in ipairs(clients) do
        local lsp_name = " " .. client.name
        table.insert(vlines, { lsp_name, "TinyInlineDiagnosticVirtualTextInfo" })
    end

    table.insert(vlines, { "", "TinyInlineInvDiagnosticVirtualTextInfoNoBg" })
    cache.tools = vlines
    valid.tools = true

    return vlines_to_inline_hl(vlines)
end

M.tabs = function()
    local active_tabpage = vim.api.nvim_tabpage_get_number(0)
    local tabs = vim.api.nvim_list_tabpages()

    local vlines = {}

    for i, tab in ipairs(tabs) do
        if tab == active_tabpage then
            table.insert(vlines, { "", "TinyInlineInvDiagnosticVirtualTextInfoNoBg" })
            table.insert(vlines, { "●", "TinyInlineDiagnosticVirtualTextInfo" })
            table.insert(vlines, { "", "TinyInlineInvDiagnosticVirtualTextInfoNoBg" })
        else
            table.insert(vlines, { "", "TinyInlineInvDiagnosticVirtualTextInfoNoBg" })
            table.insert(vlines, { "○", "TinyInlineDiagnosticVirtualTextInfo" })
            table.insert(vlines, { "", "TinyInlineInvDiagnosticVirtualTextInfoNoBg" })
        end

        if i < #tabs then
            table.insert(vlines, { " ", "Comment" })
        end
    end

    return vlines_to_inline_hl(vlines)
end

M.time = function()
    return "%#CodeLensSeparator#" .. "%#CodeLensContentIcon#" .. os.date("%H:%M") .. " "
end

M.git_branch = function()
    local local_branch = git_common.head_branch_name()
    return vlines_to_inline_hl({
        { "", "TinyInlineInvDiagnosticVirtualTextInfoNoBg" },
        { #local_branch > 0 and local_branch or "!git", "TinyInlineDiagnosticVirtualTextInfo" },
        { "", "TinyInlineInvDiagnosticVirtualTextInfoNoBg" },
    })
end

M.active = function()
    return table.concat({
        "%{%v:lua.require'ui.statusline'.mode()%}",
        "%{%v:lua.require'ui.statusline'.spotify()%}",
        "%=",
        "%{%v:lua.require'ui.statusline'.tabs()%}",
        "%{%v:lua.require'ui.statusline'.tools()%}",
        "%{%v:lua.require'ui.statusline'.git_branch()%}",
        "%{%v:lua.require'ui.statusline'.time()%}",
    }, " ")
end

M.inactive = function()
    return "%#StatusLineNC#"
end

local draw_statusline = vim.schedule_wrap(function()
    local cur_win_id = vim.api.nvim_get_current_win()
    for _, win_id in ipairs(vim.api.nvim_list_wins()) do
        vim.wo[win_id].statusline = (win_id == cur_win_id) and "%{%v:lua.require'ui.statusline'.active()%}"
            or "%{%v:lua.require'ui.statusline'.inactive()%}"
    end
end)

M.setup = function()
    vim.opt.laststatus = 3

    vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter" }, {
        group = vim.api.nvim_create_augroup("user.statusline.draw", { clear = true }),
        desc = "Attach statusline",
        callback = function()
            draw_statusline()
        end,
    })

    local invalidate_group = vim.api.nvim_create_augroup("user.statusline.invalidate", { clear = true })

    vim.api.nvim_create_autocmd("LspAttach", {
        group = invalidate_group,
        callback = function()
            valid.tools = false
        end,
    })

    local timer = vim.uv.new_timer()
    timer:start(
        0,
        FIFO_PIPE_UPDATE_TIME,
        vim.schedule_wrap(function()
            valid.spotify = false
        end)
    )
end

return M
