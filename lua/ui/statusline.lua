local M = {}

local symbols = require("symbols")

local cache = {
    stat = {},
}

local valid = {
    stat = false,
}

--- @type table<line.ChangeType, string>
local to_change_symbol = {
    file = "f",
    ins = "+",
    del = "-",
}

--- @alias line.ChangeType "file"|"ins"|"del"

--- @return line.ChangeType|nil,string|nil
local change_symbol = function(change)
    if string.find(change, "file") then
        return to_change_symbol.file, "Constant"
    elseif string.find(change, "ins") then
        return to_change_symbol.ins, "DiagnosticOk"
    elseif string.find(change, "del") then
        return to_change_symbol.del, "DiagnosticError"
    end
end

--- @return table<table<string>>
local stat = function()
    if cache.stat and valid.stat then
        return cache.stat
    end

    vim.system({ "git", "diff", "--stat" }, { text = true }, function(out)
        if #out.stdout > 0 then
            local lines = vim.split(out.stdout, "\n", { trimempty = true })
            local changes = lines[#lines]
            if changes and #changes > 0 then
                local changes_by_type = vim.split(changes, ",", { trimempty = true })
                local content = {}
                local total = 0
                for _, change in ipairs(changes_by_type) do
                    local amount = string.match(change, "%d+")
                    total = total + tonumber(vim.trim(amount))
                    local symbol, hg = change_symbol(change)
                    if symbol == "f" then
                        table.insert(content, { amount .. symbol, hg })
                    else
                        table.insert(content, { symbol .. amount, hg })
                    end
                end
                if total > 0 then
                    cache.stat = content
                else
                    cache.stat = {}
                end
            end
        else
            cache.stat = {}
        end
        valid.stat = true
    end)
    return cache.stat or {}
end

---@return string
M.active_macro_register = function()
    if vim.fn.reg_recording() ~= "" then
        return "recording @" .. vim.fn.reg_recording()
    else
        return ""
    end
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
    end
    return string.format("%%#MiniStatuslineMode%s#%s %%#MiniStatuslineMode%sSeparator#", hl, " " .. mode, hl)
end

M.tools = function()
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    local display = ""
    for _, client in ipairs(clients) do
        local symbol = symbols.lsp_servers(client.name)
        if symbol ~= "" then
            display = display .. (#display > 0 and " " or "") .. symbols.lsp_servers(client.name)
        end
    end
    -- local dap = require("dap").session() ~= nil and "%#MiniIconsGreen#" .. "󰃤 " or "%#MiniIconsYellow#" .. " "
    -- dap ..
    return (#display > 0 and "%#StatusLineSeparatorLsp#" .. display or display) .. " %#StatusLineSeparator#"
end

M.git = function()
    local content = stat()
    local expanded = ""
    for _, block in ipairs(content) do
        local s, hl = unpack(block)
        expanded = expanded .. string.format("%%#%s# %s", hl, s)
    end
    return expanded
end

M.copilot = function()
    local inline_enabled = vim.lsp.inline_completion.is_enabled() and " " or "%#Comment# "
    local success, sidekick = pcall(require, "sidekick.nes")
    if success then
        local count = #sidekick.get()
        return string.format("%%#MiniIconsPurple# %d %s", count, inline_enabled)
    else
        return "%#Comment# 0 " .. inline_enabled
    end
end

M.time = function()
    return "%#StatusLineSeparator#" .. "" .. "%#StatusLineSeparatorContent# " .. os.date("%H:%M") .. " "
end

M.active = function()
    return table.concat({
        "",
        "%{%v:lua.require'ui.statusline'.mode()%}",
        "%{%v:lua.require'ui.statusline'.tools()%}",
        -- "%=",
        "%{%v:lua.require'ui.statusline'.copilot()%}",
        "%=",
        "%{%v:lua.require'ui.statusline'.active_macro_register()%}",
        "%{%v:lua.require'ui.statusline'.git()%}",
        "%#Comment#",
        "",
        "%l:%c",
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
    vim.opt.laststatus = 2

    vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter" }, {
        group = vim.api.nvim_create_augroup("user.statusline.draw", { clear = true }),
        desc = "Attach statusline",
        callback = function()
            draw_statusline()
        end,
    })

    vim.api.nvim_create_autocmd("User", {
        pattern = "MiniGitCommandDone",
        group = vim.api.nvim_create_augroup("user.statusline.git", { clear = true }),
        desc = "refresh git stats",
        callback = vim.schedule_wrap(function()
            valid.stat = false
        end),
    })

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
        group = vim.api.nvim_create_augroup("user.statusline.git", { clear = true }),
        desc = "refresh git stats",
        callback = vim.schedule_wrap(function()
            valid.stat = false
        end),
    })
end

return M
