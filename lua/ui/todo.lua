local api = vim.api
local persist = require("persist")
local extmarks = require("ui.extmarks")
local floats = require("ui.floats")

local M = {}
local ns = api.nvim_create_namespace("user.todo")
local active_win, refresh_active, writing

local function float_width(content_width)
    return math.min(math.max(40, content_width), 60, math.max(1, vim.o.columns - 2))
end

function M.open()
    if active_win and api.nvim_win_is_valid(active_win) then
        api.nvim_set_current_win(active_win)
        return
    end

    api.nvim_set_hl(0, "TodoCompleted", { default = true, fg = "#808080", ctermfg = 8, strikethrough = true })
    local content_width = 0
    local buf, win = floats.open({
        title = " Todo ",
        width = float_width(content_width),
        height = 0.4,
        bo = { buflisted = false, bufhidden = "wipe", modifiable = false },
        wo = { cursorline = true, wrap = true, linebreak = true },
    })
    active_win = win
    local visible = {}
    local busy = false

    local function resize()
        local width = float_width(content_width)
        api.nvim_win_set_config(win, {
            relative = "editor",
            width = width,
            row = math.max(0, (vim.o.lines - api.nvim_win_get_height(win)) / 2),
            col = (vim.o.columns - width) / 2,
        })
    end
    local resize_event = api.nvim_create_autocmd("VimResized", { callback = resize })

    local saved_cursor
    local function hide_cursor()
        if saved_cursor == nil then
            saved_cursor = vim.o.guicursor
            api.nvim_set_hl(0, "TodoHiddenCursor", { blend = 100, nocombine = true })
            local rule = "n-v-ve:TodoHiddenCursor"
            vim.o.guicursor = saved_cursor == "" and rule or (saved_cursor .. "," .. rule)
        end
    end
    local function restore_cursor()
        if saved_cursor ~= nil then
            vim.o.guicursor = saved_cursor
            saved_cursor = nil
        end
    end
    api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, { buffer = buf, callback = hide_cursor })
    api.nvim_create_autocmd({ "WinLeave", "BufLeave" }, { buffer = buf, callback = restore_cursor })
    api.nvim_create_autocmd("BufWipeout", {
        buffer = buf,
        once = true,
        callback = function()
            restore_cursor()
            api.nvim_del_autocmd(resize_event)
        end,
    })
    hide_cursor()

    local function refresh()
        busy = true
        persist.run("todo", "list", {}, function(items, err)
            busy = false
            if err then
                vim.notify(err, vim.log.levels.ERROR, { title = "Todo" })
                return
            end
            if not api.nvim_win_is_valid(win) then
                return
            end

            local today = os.date("%Y-%m-%d")
            local lines = {}
            visible = {}
            content_width = 0
            for _, item in ipairs(items) do
                local completed = item.done_at ~= nil
                if not completed or item.complete_at == today then
                    local marker = completed and "● " or "○ "
                    local body = item.body:gsub("%c", " ")
                    content_width = math.max(content_width, vim.fn.strwidth(marker .. body))
                    visible[#visible + 1] = item
                    lines[#lines + 1] = {
                        { marker, completed and "Comment" or nil },
                        { body, completed and "TodoCompleted" or nil },
                    }
                end
            end
            if #lines == 0 then
                lines[1] = { { "No tasks. Press ,a to add one.", "Comment" } }
            end

            vim.bo[buf].modifiable = true
            api.nvim_buf_clear_namespace(buf, ns, 0, -1)
            extmarks.write_vlines_as_content(buf, ns, lines)
            vim.bo[buf].modifiable = false
            resize()
        end)
    end

    local function change(operation, params)
        writing = true
        persist.run("todo", operation, params, function(_, err)
            writing = false
            if err then
                vim.notify(err, vim.log.levels.ERROR, { title = "Todo" })
            end
            if api.nvim_win_is_valid(active_win) then
                refresh_active()
            end
        end)
    end

    local function prompt(item)
        busy = true
        vim.ui.input({
            prompt = item and "Edit todo: " or "Add todo: ",
            default = item and item.body or nil,
        }, function(body)
            busy = false
            if body and body:find("%S") and api.nvim_win_is_valid(win) then
                change(item and "edit" or "add", { id = item and item.id, body = body })
            end
        end)
    end

    local function map(key, action, needs_item)
        vim.keymap.set("n", key, function()
            local item = visible[api.nvim_win_get_cursor(win)[1]]
            if not busy and not writing and (item or not needs_item) then
                action(item)
            end
        end, { buffer = buf })
    end

    map(",a", function()
        prompt()
    end)
    map(",e", prompt, true)
    map(",d", function(item)
        change("delete", { id = item.id })
    end, true)
    map("<CR>", function(item)
        change("toggle", { id = item.id })
    end, true)
    vim.keymap.set("n", "<Esc>", function()
        api.nvim_win_close(win, true)
    end, { buffer = buf })

    refresh_active = refresh
    if not writing then
        refresh()
    end
end

return M
