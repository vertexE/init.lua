local attention = require("zellij.notify")
local zellij = require("zellij.zellij")
local Color = require("color")
local api = vim.api

local M = {}

local bell = ""
local notification_bell = ""
local highlights = { gray = "Comment", orange = "MiniIconsOrange", red = "MiniIconsRed" }
local label_highlight = "MiniIconsRed"
local pulse_highlight = "ZellijPickerPulse"
local cursor_highlight = "ZellijPickerHiddenCursor"
local title = " 󱙝 " .. zellij.session_name() .. " "
local left_keys, right_keys = "tsrag", "neiom"
local ns = api.nvim_create_namespace("user.zellij.picker")
local active_win

local function single_line(value)
    return (value:gsub("%c", " "))
end

local function empty()
    vim.notify("No selectable terminal tabs in nvim-mux", vim.log.levels.INFO, { title = "Zellij" })
end

local function group_items(items)
    local groups, by_directory = {}, {}
    for _, item in ipairs(items) do
        local pane = item.pane
        local key = pane.cwd or pane.directory
        local group = by_directory[key]
        if not group then
            group = { directory = pane.directory, items = {} }
            by_directory[key] = group
            groups[#groups + 1] = group
        end
        group.items[#group.items + 1] = item
    end
    return groups
end

function M.pick(tabs, open_tab)
    if active_win and api.nvim_win_is_valid(active_win) then
        api.nvim_set_current_win(active_win)
        return
    end
    if #tabs == 0 then
        empty()
        return
    end

    local items = vim.tbl_map(function(pane)
        return { pane = pane }
    end, tabs)
    local labels, index = {}, 0
    for _, group in ipairs(group_items(items)) do
        for _, item in ipairs(group.items) do
            local left = math.floor(index / #right_keys) + 1
            local right = index % #right_keys + 1
            if left <= #left_keys then
                item.label = left_keys:sub(left, left) .. right_keys:sub(right, right)
                labels[item.label] = item
            end
            index = index + 1
        end
    end

    local buf = api.nvim_create_buf(false, true)
    vim.b[buf].miniindentscope_disable = true
    vim.bo[buf].bufhidden = "wipe"
    local win, prefix, pulse
    local width, height
    local row_items = {}

    local function layout()
        local columns = vim.o.columns
        local lines = vim.o.lines - vim.o.cmdheight
        local w = math.max(1, math.min(width, columns - 2))
        local h = math.max(1, math.min(height, lines - 2))
        return {
            relative = "editor",
            row = math.max(0, math.floor((lines - h - 2) / 2)),
            col = math.max(0, math.floor((columns - w - 2) / 2)),
            width = w,
            height = h,
            border = "rounded",
            title = title,
            title_pos = "center",
        }
    end

    local function draw()
        local lines, spans = {}, {}
        local view = win and api.nvim_win_call(win, vim.fn.winsaveview)
        local selected = view and row_items[view.lnum]
        local selected_row
        row_items = {}
        width = math.max(25, vim.fn.strdisplaywidth(title))

        local function add_row(chunks, next_key)
            local i = #lines + 1
            local line = ""
            spans[i] = {}
            for j, chunk in ipairs(chunks) do
                local value, highlight = chunk[1], chunk[2]
                if prefix then
                    highlight = j == next_key and label_highlight or "Comment"
                end
                local col = #line
                line = line .. value
                if highlight then
                    spans[i][#spans[i] + 1] = { col, #line, highlight }
                end
            end
            lines[i] = line
            width = math.max(width, vim.fn.strdisplaywidth(line))
        end

        for i, group in ipairs(group_items(items)) do
            if i > 1 then
                add_row({})
            end
            add_row({ { single_line(group.directory), "MiniIconsGreen" } })
            for _, item in ipairs(group.items) do
                local pane = item.pane
                local indicator = attention.from_pane(pane).indicator
                local glyph = (indicator == "orange" or indicator == "red") and notification_bell or bell
                local indicator_hl = highlights[indicator]
                if indicator == "spinner" then
                    glyph, indicator_hl = "●", pulse_highlight
                end
                local label = item.label or "  "
                local left, right = label:sub(1, 1), label:sub(2, 2)
                add_row({
                    { "  " .. left, label_highlight },
                    { right, label_highlight },
                    { " " .. glyph, indicator_hl },
                    { " " .. single_line(pane.command), indicator == "orange" and highlights.orange or "MiniIconsGreen" },
                }, prefix == left and 2 or nil)
                row_items[#lines] = item
                if selected == item then
                    selected_row = #lines
                end
            end
        end
        height = #lines

        if not vim.deep_equal(lines, api.nvim_buf_get_lines(buf, 0, -1, false)) then
            vim.bo[buf].modifiable = true
            api.nvim_buf_set_lines(buf, 0, -1, false, lines)
            vim.bo[buf].modifiable = false
            if view then
                if selected_row then
                    view.topline = math.max(1, view.topline + selected_row - view.lnum)
                    view.lnum = selected_row
                end
                api.nvim_win_call(win, function()
                    vim.fn.winrestview(view)
                end)
            end
        end

        api.nvim_buf_clear_namespace(buf, ns, 0, -1)
        for i, row in ipairs(spans) do
            for _, span in ipairs(row) do
                api.nvim_buf_set_extmark(buf, ns, i - 1, span[1], { end_col = span[2], hl_group = span[3] })
            end
        end
    end

    draw()
    win = api.nvim_open_win(buf, true, vim.tbl_extend("force", layout(), { style = "minimal" }))
    active_win = win
    vim.wo[win].wrap = false
    vim.wo[win].cursorline = true
    api.nvim_win_set_cursor(win, { 2, 0 })

    local saved_cursor
    local function hide_cursor()
        if saved_cursor == nil then
            saved_cursor = vim.o.guicursor
            api.nvim_set_hl(0, cursor_highlight, { blend = 100, nocombine = true })
            local rule = "n-v-ve:" .. cursor_highlight
            vim.o.guicursor = saved_cursor == "" and rule or (saved_cursor .. "," .. rule)
        end
    end
    local function restore_cursor()
        if saved_cursor ~= nil then
            vim.o.guicursor = saved_cursor
            api.nvim_set_hl(0, cursor_highlight, {})
            saved_cursor = nil
        end
    end
    api.nvim_create_autocmd("WinEnter", { buffer = buf, callback = hide_cursor })
    api.nvim_create_autocmd("WinLeave", { buffer = buf, callback = restore_cursor })
    hide_cursor()

    local function stop_pulse()
        if pulse then
            pulse:stop()
            pulse:close()
            pulse = nil
        end
    end

    local function sync_pulse()
        for _, item in ipairs(items) do
            if attention.from_pane(item.pane).indicator == "spinner" then
                if not pulse then
                    local fg = api.nvim_get_hl(0, { name = "MiniIconsGreen", link = false }).fg
                    local green = Color:from_hex(("#%06x"):format(fg or 0x00d787))
                    api.nvim_set_hl(0, pulse_highlight, { fg = green:hex() })
                    local phase = 0
                    local timer = assert(vim.uv.new_timer())
                    pulse = timer
                    timer:start(75, 75, vim.schedule_wrap(function()
                        if pulse == timer then
                            phase = (phase + 1) % 16
                            local fade = (1 - math.cos(phase * math.pi / 8)) / 2
                            api.nvim_set_hl(0, pulse_highlight, { fg = green:darken(green.l * 0.4 * fade):hex() })
                        end
                    end))
                end
                return
            end
        end
        stop_pulse()
    end
    sync_pulse()

    local function close()
        api.nvim_win_close(win, true)
    end

    local function select(item)
        close()
        vim.schedule(function()
            open_tab(item.pane)
        end)
    end

    local function keymap(key, callback)
        vim.keymap.set("n", key, callback, { buffer = buf, nowait = true })
    end

    local function available_prefix(key)
        for label in pairs(labels) do
            if label:sub(1, 1) == key then
                return key
            end
        end
    end

    for key in (left_keys .. right_keys):gmatch(".") do
        keymap(key, function()
            local item = prefix and labels[prefix .. key]
            if item then
                select(item)
                return
            end
            prefix = available_prefix(key)
            draw()
        end)
    end
    keymap("<BS>", function()
        prefix = nil
        draw()
    end)
    keymap("<Esc>", close)
    keymap("q", close)
    keymap("<CR>", function()
        local item = row_items[api.nvim_win_get_cursor(win)[1]]
        if item then
            select(item)
        end
    end)

    local resize = api.nvim_create_autocmd("VimResized", {
        callback = function()
            api.nvim_win_set_config(win, layout())
        end,
    })
    local unsubscribe = attention.subscribe(function(panes, err)
        if err then
            close()
            vim.notify(err.message, vim.log.levels.WARN, { title = "Zellij" })
            return
        end
        local by_id = {}
        for _, pane in ipairs(panes) do
            by_id[pane.pane_id] = pane
        end
        for i = #items, 1, -1 do
            local item = items[i]
            local pane = by_id[item.pane.pane_id]
            if pane then
                item.pane = pane
            else
                table.remove(items, i)
                if item.label then
                    labels[item.label] = nil
                end
            end
        end
        if #items == 0 then
            close()
            empty()
            return
        end
        prefix = available_prefix(prefix)
        draw()
        api.nvim_win_set_config(win, layout())
        sync_pulse()
    end)
    api.nvim_create_autocmd("BufWipeout", {
        buffer = buf,
        once = true,
        callback = function()
            active_win = nil
            api.nvim_del_autocmd(resize)
            unsubscribe()
            stop_pulse()
            restore_cursor()
            vim.schedule(function()
                if api.nvim_win_is_valid(win) then
                    close()
                end
            end)
        end,
    })
end

return M
