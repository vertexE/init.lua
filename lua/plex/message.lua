local picker = require("plex")
local textarea = require("ui.textarea")
local api = vim.api

local M = {}

local function xml_escape(value)
    return (value:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"))
end

local function file_path(buf)
    if vim.bo[buf].buftype == "" then
        local path = api.nvim_buf_get_name(buf)
        if path ~= "" then
            return xml_escape(path)
        end
    end
end

local function editor_context()
    local context = { "<editor_context>", "  <open_files>" }
    for _, buf in ipairs(api.nvim_list_bufs()) do
        if api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted then
            local path = file_path(buf)
            if path then
                context[#context + 1] = "    <file>" .. path .. "</file>"
            end
        end
    end
    context[#context + 1] = "  </open_files>"

    local path = file_path(api.nvim_get_current_buf())
    local line, col = unpack(api.nvim_win_get_cursor(0))
    local file = path and (' file="%s"'):format(path) or ""
    context[#context + 1] = ('  <cursor%s line="%d" column="%d" />'):format(file, line, col + 1)
    context[#context + 1] = "</editor_context>"
    return table.concat(context, "\n")
end

function M.pick()
    local context = editor_context()
    picker.pick(function(tab, strategy)
        textarea.open({
            prompt = "Send message to " .. tab.tab_name:gsub("%c", " "),
            height = 5,
            submit_on_enter = true,
        }, function(lines)
            local message = table.concat(lines, "\n")
            if vim.trim(message) == "" then
                return
            end
            strategy.send_message(tab.pane_id, message .. "\n\n" .. context, function(err)
                if err then
                    vim.notify(err.message, vim.log.levels.WARN, { title = "Plex" })
                end
            end)
        end)
    end)
end

return M
