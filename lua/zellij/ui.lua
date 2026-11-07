local attention = require("zellij.notify")

local M = {}

local bell = ""
local notification_bell = ""
local separator = ""
local highlights = { gray = "Comment", orange = "MiniIconsOrange", red = "MiniIconsRed" }

local function single_line(value)
    return (value:gsub("%c", " "))
end

local function update(item, pane)
    item.pane = pane
    item.indicator = attention.from_pane(pane).indicator
    item.text = single_line(table.concat({
        pane.directory,
        pane.cwd or "",
        pane.command,
        pane.raw_command or "",
        pane.tab_name,
    }, " "))
end

function M.pick(tabs, open_tab)
    if #tabs == 0 then
        vim.notify("No selectable terminal tabs in nvim-mux", vim.log.levels.INFO, { title = "Zellij" })
        return
    end

    local snacks = require("snacks")
    local items = {}
    for i, pane in ipairs(tabs) do
        local item = {}
        update(item, pane)
        items[i] = item
    end

    local spinner
    local unsubscribe
    local function stop_spinner()
        if spinner then
            spinner:stop()
            spinner:close()
            spinner = nil
        end
    end

    snacks.picker.pick("zellij_tabs", {
        title = "Zellij · nvim-mux",
        items = items,
        layout = { preset = "vscode" },
        sort = { fields = { "score:desc", "idx" } },
        format = function(item, picker)
            local glyph = (item.indicator == "orange" or item.indicator == "red") and notification_bell or bell
            local highlight = highlights[item.indicator]
            if item.indicator == "spinner" then
                glyph = snacks.util.spinner()
                highlight = "SnacksPickerSpinner"
                if not spinner then
                    local handle = assert(vim.uv.new_timer())
                    spinner = handle
                    handle:start(150, 150, vim.schedule_wrap(function()
                        if spinner ~= handle then
                            return
                        end
                        for _, visible in ipairs(picker.list.visible) do
                            if visible.indicator == "spinner" then
                                picker.list:update({ force = true })
                                return
                            end
                        end
                        stop_spinner()
                    end))
                end
            end
            return {
                { glyph, highlight },
                { " " .. single_line(item.pane.directory) .. " ", "MiniIconsGreen" },
                { separator .. " ", "Comment" },
                { single_line(item.pane.command), "MiniIconsGreen" },
            }
        end,
        on_show = function(picker)
            unsubscribe = attention.subscribe(function(panes, err)
                if err then
                    picker:close()
                    vim.notify(err.message, vim.log.levels.WARN, { title = "Zellij" })
                    return
                end
                local by_id = {}
                for _, pane in ipairs(panes) do
                    by_id[pane.pane_id] = pane
                end
                for _, item in ipairs(items) do
                    local pane = by_id[item.pane.pane_id]
                    if pane then
                        update(item, pane)
                    end
                end
                picker.list:update({ force = true })
            end)
        end,
        on_close = function()
            stop_spinner()
            if unsubscribe then
                unsubscribe()
                unsubscribe = nil
            end
        end,
        confirm = function(picker, item)
            picker:close()
            if item then
                vim.schedule(function()
                    open_tab(item.pane)
                end)
            end
        end,
    })
end

return M
