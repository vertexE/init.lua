local attention = require("plex.notify")
local api = vim.api

local M = {}

local bell = ""
local notification_bell = ""
local spinner = require("symbols").braille_spinner_frames[1]
local highlights = { gray = "Comment", orange = "MiniIconsOrange", red = "MiniIconsRed" }
local label_highlight = "MiniIconsRed"
local keys = "asdfghjkl"
local suffixes = {}
local bindings = {}
local tabs_by_key = {}

for first in keys:gmatch(".") do
    suffixes[#suffixes + 1] = "j" .. first
end
for first in keys:gmatch(".") do
    for second in keys:gmatch(".") do
        suffixes[#suffixes + 1] = "j;" .. first .. second
    end
end

local function single_line(value)
    return (value:gsub("%c", " "))
end

local function group_tabs(tabs)
    local groups, by_directory = {}, {}
    for _, tab in ipairs(tabs) do
        local key = tab.cwd or tab.directory
        local group = by_directory[key]
        if not group then
            group = { directory = tab.directory, tabs = {} }
            by_directory[key] = group
            groups[#groups + 1] = group
        end
        group.tabs[#group.tabs + 1] = tab
    end
    return groups
end

local function terminal_chunks(pane)
    local indicator = attention.from_pane(pane).indicator
    local glyph = (indicator == "orange" or indicator == "red") and notification_bell or bell
    local indicator_hl = highlights[indicator]
    if indicator == "spinner" then
        glyph, indicator_hl = spinner, "MiniIconsGreen"
    end
    local chunks = {
        { glyph, indicator_hl },
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
    return chunks
end

function M.update_bindings(tabs, on_select)
    local prefix = vim.fn.keytrans(api.nvim_replace_termcodes("<LocalLeader>j", true, true, true))
    local mapped = {}
    for _, map in ipairs(api.nvim_get_keymap("n")) do
        mapped[map.lhs] = map
    end

    local function available(lhs, own)
        for key in pairs(mapped) do
            if key ~= own and (vim.startswith(key, lhs) or vim.startswith(lhs, key)) then
                return false
            end
        end
        return true
    end

    local by_id = {}
    for _, tab in ipairs(tabs) do
        by_id[tab.tab_id] = tab
    end
    tabs_by_key = {}
    for id, binding in pairs(bindings) do
        local map = mapped[binding.lhs]
        local owned = map and map.callback == binding.select
        if owned and by_id[id] and binding.prefix == prefix and available(binding.lhs, binding.lhs) then
            tabs_by_key[binding.lhs] = by_id[id]
        else
            if owned then
                vim.keymap.del("n", binding.lhs)
                mapped[binding.lhs] = nil
            end
            bindings[id] = nil
        end
    end

    for _, group in ipairs(group_tabs(tabs)) do
        for _, tab in ipairs(group.tabs) do
            if not bindings[tab.tab_id] then
                for _, suffix in ipairs(suffixes) do
                    local lhs = vim.fn.keytrans(api.nvim_replace_termcodes("<LocalLeader>" .. suffix, true, true, true))
                    if available(lhs) then
                        local function select()
                            on_select(tabs_by_key[lhs])
                        end
                        vim.keymap.set("n", "<LocalLeader>" .. suffix, select, {
                            desc = "Plex: open tab " .. tostring(tab.tab_id),
                        })
                        mapped[lhs] = true
                        bindings[tab.tab_id] = { lhs = lhs, prefix = prefix, select = select }
                        tabs_by_key[lhs] = tab
                        break
                    end
                end
            end
        end
    end
end

function M.choose_tab()
    if next(tabs_by_key) == nil then
        vim.notify("No Plex shortcuts available", vim.log.levels.INFO, { title = "Plex" })
        return
    end
    local key = vim.fn.input("Plex shortcut: ")
    if key == "" then
        return
    end
    local tab = tabs_by_key[key]
    if not tab then
        vim.notify("Unknown Plex shortcut: " .. key, vim.log.levels.WARN, { title = "Plex" })
    end
    return tab
end

function M.status_rows(tabs)
    local rows = {}
    for _, group in ipairs(group_tabs(tabs)) do
        rows[#rows + 1] = {}
        rows[#rows + 1] = { { single_line(group.directory), "MiniIconsGreen" } }
        for _, tab in ipairs(group.tabs) do
            local chunks = terminal_chunks(tab)
            local binding = bindings[tab.tab_id]
            table.insert(chunks, 1, { binding and ("  " .. binding.lhs .. " ") or "  ", label_highlight })
            rows[#rows + 1] = chunks
        end
    end
    return rows
end

return M
