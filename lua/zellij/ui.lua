local attention = require("zellij.notify")
local zellij = require("zellij.zellij")
local api = vim.api

local M = {}

local bell = ""
local notification_bell = ""
local spinner_frames = require("symbols").braille_spinner_frames
local highlights = { gray = "Comment", orange = "MiniIconsOrange", red = "MiniIconsRed" }
local label_highlight = "MiniIconsRed"
local cursor_highlight = "ZellijPickerHiddenCursor"
local row_highlight = "ZellijPickerCurrentRow"
local title = " 󱙝 " .. zellij.session_name() .. " "
local left_keys, right_keys = "tsrag", "neiom"
local ns = api.nvim_create_namespace("user.zellij.picker")
local row_ns = api.nvim_create_namespace("user.zellij.picker.cursor")
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

function M.pick(tabs, on_select)
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
    local labels = {}
    local function assign_labels()
        labels = {}
        local index = 0
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
    end
    assign_labels()

    local buf = api.nvim_create_buf(false, true)
    vim.b[buf].miniindentscope_disable = true
    vim.bo[buf].bufhidden = "wipe"
    local win, prefix, spinner_timer
    local spinner_frame = 1
    local spinner_marks = {}
    local width, height
    local row_items = {}

    local function underline_row()
        local row = api.nvim_win_get_cursor(win)[1] - 1
        local line = api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
        local first = line:find("%S")
        api.nvim_buf_clear_namespace(buf, row_ns, 0, -1)
        if first then
            api.nvim_buf_set_extmark(buf, row_ns, row, first - 1, {
                end_col = #line,
                hl_group = row_highlight,
                priority = 200,
            })
        end
    end

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

    local function draw_spinners()
        for _, mark in ipairs(spinner_marks) do
            mark.id = api.nvim_buf_set_extmark(buf, ns, mark.row, mark.col, {
                id = mark.id,
                virt_text = { { spinner_frames[spinner_frame], mark.hl } },
                virt_text_pos = "overlay",
                hl_mode = "combine",
            })
        end
    end

    local function draw()
        local lines, spans = {}, {}
        local view = win and api.nvim_win_call(win, vim.fn.winsaveview)
        local selected = view and row_items[view.lnum]
        local selected_row
        row_items = {}
        spinner_marks = {}
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
                    glyph, indicator_hl = spinner_frames[1], "MiniIconsGreen"
                end
                local label = item.label or "  "
                local left, right = label:sub(1, 1), label:sub(2, 2)
                local chunks = {
                    { "  " .. left, label_highlight },
                    { right, label_highlight },
                    { " " .. glyph, indicator_hl },
                    { " " .. single_line(pane.command), indicator == "orange" and highlights.orange or "MiniIconsGreen" },
                }
                if pane.tab_tag then
                    vim.list_extend(chunks, {
                        { " " },
                        { "", "CodeLensSeparator" },
                        { single_line(pane.tab_tag), "CodeLensContentIcon" },
                        { "", "CodeLensSeparator" },
                    })
                end
                add_row(chunks, prefix == left and 2 or nil)
                if indicator == "spinner" then
                    spinner_marks[#spinner_marks + 1] = {
                        row = #lines - 1,
                        col = #chunks[1][1] + #chunks[2][1] + 1, -- Skip shortcut and following space.
                        hl = prefix and "Comment" or indicator_hl,
                    }
                end
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
        draw_spinners()
        if win then
            underline_row()
        end
    end

    draw()
    win = api.nvim_open_win(buf, true, vim.tbl_extend("force", layout(), { style = "minimal" }))
    active_win = win
    vim.wo[win].wrap = false
    vim.wo[win].cursorline = true
    api.nvim_win_set_cursor(win, { 1, 0 })
    api.nvim_set_hl(0, row_highlight, { underline = true, cterm = { underline = true } })
    api.nvim_create_autocmd("CursorMoved", { buffer = buf, callback = underline_row })
    underline_row()

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

    local function stop_spinner()
        if spinner_timer then
            spinner_timer:stop()
            spinner_timer:close()
            spinner_timer = nil
            spinner_frame = 1
        end
    end

    local function sync_spinner()
        if #spinner_marks == 0 then
            stop_spinner()
        elseif not spinner_timer then
            local timer = assert(vim.uv.new_timer())
            spinner_timer = timer
            timer:start(75, 75, vim.schedule_wrap(function()
                if spinner_timer == timer then
                    spinner_frame = spinner_frame % #spinner_frames + 1
                    draw_spinners()
                end
            end))
        end
    end
    sync_spinner()

    local function close()
        api.nvim_win_close(win, true)
    end

    local function select(item)
        close()
        vim.schedule(function()
            on_select(item.pane)
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
    local tagging = false
    keymap(",t", function()
        local item = row_items[api.nvim_win_get_cursor(win)[1]]
        if tagging or not item then
            return
        end
        local cancelled = "\n"
        local ok, value = pcall(vim.fn.input, {
            prompt = "Tag: ",
            default = item.pane.tab_tag or "",
            cancelreturn = cancelled,
        })
        if not ok or value == cancelled or not api.nvim_win_is_valid(win) then
            return
        end
        local tag = vim.trim(single_line(value))
        tag = tag ~= "" and tag or nil
        local pane = item.pane
        if tag == pane.tab_tag then
            return
        end

        tagging = true
        zellij.set_tab_tag(pane.tab_id, pane.tab_name, tag, function(name, err)
            tagging = false
            if err then
                vim.notify(err.message, vim.log.levels.WARN, { title = "Zellij" })
            end
            if not name or not api.nvim_win_is_valid(win) then
                return
            end
            for _, current in ipairs(items) do
                if current.pane.tab_id == pane.tab_id then
                    current.pane.tab_name, current.pane.tab_tag = name, tag
                end
            end
            prefix = nil
            draw()
            api.nvim_win_set_config(win, layout())
        end)
    end)
    local creating = false
    keymap(",a", function()
        if creating then
            return
        end
        local cwd = vim.fn.getcwd()
        local ok, directory = pcall(vim.fn.input, { prompt = "Open: ", default = cwd, completion = "dir" })
        if not ok or directory == "" then
            return
        end
        directory = vim.fn.fnamemodify(directory, ":p")
        creating = true
        zellij.new_tab(directory, function(err)
            if err then
                creating = false
                vim.notify(err.message, vim.log.levels.WARN, { title = "Zellij" })
                return
            end
            zellij.tabs(function(updated, query_err)
                creating = false
                if query_err then
                    vim.notify(query_err.message, vim.log.levels.WARN, { title = "Zellij" })
                    return
                end
                if not api.nvim_win_is_valid(win) then
                    return
                end
                items = vim.tbl_map(function(pane)
                    return { pane = pane }
                end, updated)
                prefix = nil
                assign_labels()
                draw()
                api.nvim_win_set_config(win, layout())
                sync_spinner()
            end)
        end)
    end)
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
        sync_spinner()
    end)
    api.nvim_create_autocmd("BufWipeout", {
        buffer = buf,
        once = true,
        callback = function()
            active_win = nil
            api.nvim_del_autocmd(resize)
            unsubscribe()
            stop_spinner()
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
