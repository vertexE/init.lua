local M = {}

local symbols = require("core.ui.symbols")

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
    return string.format("%%#MiniStatuslineMode%s#%s", hl, " " .. mode)
end

M.tools = function()
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    local client_symbols = vim.iter(clients)
        :map(function(client)
            return "%#MiniIconsBlue#" .. symbols.lsp_servers(client.name)
        end)
        :join(" ")
    local dap = require("dap").session() ~= nil and "%#MiniIconsGreen#" .. "󰃤 " or "%#MiniIconsRed#" .. " "
    return dap .. " " .. client_symbols
end

M.active = function()
    return table.concat({
        "",
        "%{%v:lua.require'core.ui.statusline'.mode()%}",
        "%#StatusLine#",
        "%{%v:lua.require'core.ui.statusline'.tools()%}",
        "%=",
        "%{%v:lua.require'core.ui.statusline'.active_macro_register()%}",
        "",
        "%l:%c",
        "",
    }, " ")
end

M.inactive = function()
    return "%#StatusLineNC#"
end

local draw_statusline = vim.schedule_wrap(function()
    local cur_win_id = vim.api.nvim_get_current_win()
    for _, win_id in ipairs(vim.api.nvim_list_wins()) do
        vim.wo[win_id].statusline = (win_id == cur_win_id) and "%{%v:lua.require'core.ui.statusline'.active()%}"
            or "%{%v:lua.require'core.ui.statusline'.inactive()%}"
    end
end)

M.setup = function()
    vim.opt.laststatus = 2
    vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter" }, {
        group = vim.api.nvim_create_augroup("user/statusline", { clear = true }),
        desc = "Attach statusline",
        callback = function()
            draw_statusline()
        end,
    })
end

return M
