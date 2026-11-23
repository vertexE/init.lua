local M = {}
local api = vim.api
local plex = require("plex")
local attention = require("plex.notify")
local keys = "neiotsra"
local shells = { shell = true, sh = true, bash = true, zsh = true, fish = true, nu = true }
local agents = { claude = true, codex = true, gemini = true, opencode = true, aider = true }
local groups, selected, popup, buffer, timer = {}, nil, nil, nil, nil
local frame, offset = 0, 0
local positions = {}
local saved_cursor
local refresh

local function clean(value)
    return tostring(value):gsub("%c", " ")
end

local function hl(name)
    return api.nvim_get_hl(0, { name = name, link = false })
end

local function blend(fg, bg, amount)
    local color = 0
    for _, place in ipairs({ 65536, 256, 1 }) do
        local a, b = math.floor(fg / place) % 256, math.floor(bg / place) % 256
        color = color + math.floor(b + (a - b) * amount + 0.5) * place
    end
    return color
end

local function highlights()
    api.nvim_set_hl(0, "TabHiddenCursor", { blend = 100, nocombine = true })
    local base = hl("TabLineFill").bg or hl("Normal").bg or 0x000000
    local surface = hl("CodeLensContentIcon").bg or blend(0xFFFFFF, base, 0.1)
    local focus = blend(hl("MiniIconsGreen").fg or 0x00D787, surface, 0.18)
    local green = hl("MiniIconsGreen").fg or 0x00D787
    local orange = hl("MiniIconsOrange").fg or 0xFFAF00
    for _, item in ipairs({ { "NoFocus", surface }, { "Focus", focus }, { "Menu", hl("MenuNormal").bg or surface } }) do
        local prefix, bg = "Tab" .. item[1], item[2]
        api.nvim_set_hl(0, prefix .. "Content", { fg = (item[1] == "Menu" and hl("Normal").fg or hl("Comment").fg) or 0x888888, bg = bg })
        api.nvim_set_hl(0, prefix .. "Label", { fg = hl("CodeLensContentIcon").fg or green, bg = bg, bold = item[1] == "Focus" })
        api.nvim_set_hl(0, prefix .. "Separator", { fg = bg, bg = base })
        api.nvim_set_hl(0, prefix .. "Attention", { fg = orange, bg = bg })
        for i = 0, 8 do
            api.nvim_set_hl(0, prefix .. "Pulse" .. i, { fg = blend(green, bg, 0.15 + i * 0.10625), bg = bg })
        end
    end
end

local function current_index()
    for i, group in ipairs(groups) do
        if group.key == selected then
            return i
        end
    end
    return 1
end

local function process(pane, prefix)
    local command = pane.command or "shell"
    local agent = agents[command]
    local state = attention.from_pane(pane).status
    local active = state == "working" or (state == "idle" and not agent and not shells[command])
    local needs = state == "needs_input" or state == "failed"
    local icon = agent and "󰫢" or command == "lazygit" and "" or ""
    local group = prefix .. "Content"
    if needs then
        group = prefix .. "Attention"
    elseif active and command ~= "lazygit" then
        -- Agents double-pulse; ordinary foreground commands breathe continuously.
        local phase = agent and ({ 0, 4, 8, 4, 0, 4, 8, 4, 0, 0, 0, 0 })[frame % 12 + 1]
            or math.floor((math.sin(frame * math.pi / 8) + 1) * 4 + 0.5)
        group = prefix .. "Pulse" .. phase
    end
    return icon, group, active, needs, state
end

local function segment(group)
    local prefix = "Tab" .. (popup and group.key == selected and "Focus" or "NoFocus")
    local chunks = {
        { "", prefix .. "Separator" },
        { " " .. clean(group.directory) .. " - ", prefix .. "Label" },
    }
    for i, pane in ipairs(group.tabs) do
        local icon, color = process(pane, prefix)
        chunks[#chunks + 1] = { (i > 1 and " " or "") .. icon, color }
    end
    chunks[#chunks + 1] = { " ", prefix .. "Content" }
    chunks[#chunks + 1] = { "", prefix .. "Separator" }
    chunks[#chunks + 1] = { " ", "TabLineFill" }
    return chunks
end

function M.render()
    local result, col = { "%#TabLineFill# " }, 1
    positions = {}
    local start = popup and offset + 1 or 1
    for i = start, #groups do
        positions[i] = col
        for _, chunk in ipairs(segment(groups[i])) do
            result[#result + 1] = "%#" .. chunk[2] .. "#" .. chunk[1]:gsub("%%", "%%%%")
            col = col + vim.fn.strdisplaywidth(chunk[1])
        end
    end
    return table.concat(result) .. "%#TabLineFill#"
end

local function restore_cursor()
    if saved_cursor ~= nil then
        vim.o.guicursor = saved_cursor
        saved_cursor = nil
    end
end

local function close()
    restore_cursor()
    local win = popup
    popup, buffer = nil, nil
    if win and api.nvim_win_is_valid(win) then
        api.nvim_win_close(win, true)
    end
    vim.cmd.redrawtabline()
end

local function choose(index)
    local group = groups[current_index()]
    local pane = group and group.tabs[index]
    if pane then
        close()
        plex.open_tab(pane)
    end
end

local function draw_popup()
    if not popup or not api.nvim_win_is_valid(popup) then
        return
    end
    local group = groups[current_index()]
    local rows, chunks, width = {}, {}, 24
    for i, pane in ipairs(group and group.tabs or {}) do
        local _, color, active, needs, state = process(pane, "TabMenu")
        local shortcut = i <= #keys and ("󱁐 " .. keys:sub(i, i)) or "   "
        local status = needs and (state == "failed" and "failed" or "needs attention")
            or active and "working" or state == "done" and "finished" or "idle"
        local text = "  " .. shortcut .. "  ● " .. clean(pane.command or "shell") .. " · " .. status
        if pane.tab_tag then
            text = text .. "  [" .. clean(pane.tab_tag) .. "]"
        end
        rows[#rows + 1] = text
        chunks[#chunks + 1] = { #shortcut + 4, #shortcut + 4 + #"●", color }
        width = math.max(width, vim.fn.strdisplaywidth(text) + 2)
    end
    if #rows == 0 then
        rows = { "No Plex processes" }
    end
    width = math.min(width, math.max(1, vim.o.columns - 2))
    local col = math.min(positions[current_index()] or 0, math.max(0, vim.o.columns - width - 2))
    api.nvim_win_set_config(popup, { relative = "editor", row = 1, col = col, width = width,
        height = math.min(#rows, math.max(1, vim.o.lines - 5)) })
    vim.bo[buffer].modifiable = true
    api.nvim_buf_set_lines(buffer, 0, -1, false, rows)
    vim.bo[buffer].modifiable = false
    local ns = api.nvim_create_namespace("user.tabline.popup")
    api.nvim_buf_clear_namespace(buffer, ns, 0, -1)
    for i, chunk in ipairs(chunks) do
        api.nvim_buf_set_extmark(buffer, ns, i - 1, chunk[1], { end_col = chunk[2], hl_group = chunk[3] })
    end
    if group and #group.tabs > 0 then
        local row = api.nvim_win_get_cursor(popup)[1] - 1
        api.nvim_buf_set_extmark(buffer, ns, row, 0, {
            virt_text = { { "", "TabMenuLabel" } }, virt_text_pos = "overlay",
        })
    end
end

refresh = function()
    if popup then
        local index = current_index()
        offset = math.min(offset, index - 1)
        M.render()
        if (positions[index] or 0) > math.max(0, vim.o.columns - 24) then
            offset = index - 1
        end
        M.render()
        draw_popup()
    end
    vim.cmd.redrawtabline()
end

function M.open()
    plex.prepare()
    if popup and api.nvim_win_is_valid(popup) then
        api.nvim_set_current_win(popup)
        return
    end
    selected = groups[current_index()] and groups[current_index()].key or nil
    buffer = api.nvim_create_buf(false, true)
    vim.bo[buffer].bufhidden = "wipe"
    popup = api.nvim_open_win(buffer, true, { relative = "editor", row = 1, col = 0,
        width = 24, height = 1, style = "minimal", border = "rounded" })
    vim.wo[popup].winhighlight = "Normal:MenuNormal,NormalFloat:MenuNormal,FloatBorder:MenuBorder,CursorLine:MenuSelection"
    vim.wo[popup].wrap = false
    vim.wo[popup].winblend = 0
    vim.wo[popup].cursorline = true
    vim.wo[popup].cursorlineopt = "line"
    saved_cursor = vim.o.guicursor
    vim.o.guicursor = (saved_cursor ~= "" and saved_cursor .. "," or "") .. "a:TabHiddenCursor"
    api.nvim_create_autocmd("CursorMoved", { buffer = buffer, callback = draw_popup })
    local function map(lhs, callback)
        vim.keymap.set("n", lhs, callback, { buffer = buffer, silent = true, nowait = true })
    end
    for key, delta in pairs({ h = -1, l = 1 }) do
        map(key, function()
            if #groups > 0 then
                selected = groups[(current_index() - 1 + delta) % #groups + 1].key
                refresh()
            end
        end)
    end
    for i = 1, #keys do
        local index = i
        map("<leader>" .. keys:sub(i, i), function() choose(index) end)
    end
    map(",t", function()
        local directory = groups[current_index()]
        local pane = directory and directory.tabs[api.nvim_win_get_cursor(popup)[1]]
        if not pane then return end
        close()
        plex.tag_tab(pane)
    end)
    map("<CR>", function() choose(api.nvim_win_get_cursor(popup)[1]) end)
    map("<Esc>", close)
    map("<C-t>", close)
    map("q", close)
    local popup_win = popup
    api.nvim_create_autocmd("WinClosed", { pattern = tostring(popup), once = true, callback = function()
        if popup == popup_win then
            restore_cursor()
            popup, buffer = nil, nil
        end
        vim.schedule(function() vim.cmd.redrawtabline() end)
    end })
    api.nvim_create_autocmd("WinLeave", { buffer = buffer, once = true, callback = function()
        restore_cursor()
        vim.schedule(function()
            if popup == popup_win then close() end
        end)
    end })
    refresh()
end

function M.setup()
    highlights()
    vim.o.showtabline = 2
    vim.o.tabline = "%!v:lua.require'ui.tabline'.render()"
    local group = api.nvim_create_augroup("user.tabline", { clear = true })
    api.nvim_create_autocmd("ColorScheme", { group = group, callback = function() highlights(); refresh() end })
    api.nvim_create_autocmd("VimResized", { group = group, callback = refresh })
    local unsubscribe = plex.subscribe_tabs(function(tabs)
        groups = {}
        local by_directory = {}
        for _, pane in ipairs(tabs) do
            local key = pane.cwd or pane.directory
            if not by_directory[key] then
                local entry = { key = key, directory = pane.directory, tabs = {} }
                by_directory[key] = entry
                groups[#groups + 1] = entry
            end
            table.insert(by_directory[key].tabs, pane)
        end
        selected = groups[current_index()] and groups[current_index()].key or nil
        refresh()
    end)
    timer = assert(vim.uv.new_timer())
    timer:start(100, 100, vim.schedule_wrap(function()
        if timer:is_closing() then return end
        for _, directory in ipairs(groups) do
            for _, pane in ipairs(directory.tabs) do
                local _, _, active = process(pane, "TabNoFocus")
                if active then
                    frame = frame + 1
                    refresh()
                    return
                end
            end
        end
    end))
    api.nvim_create_autocmd("VimLeavePre", { group = group, once = true, callback = function()
        timer:stop()
        timer:close()
        unsubscribe()
    end })
end

return M
