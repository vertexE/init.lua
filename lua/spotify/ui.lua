local M = {}
local api = vim.api

local function blend(fg, bg, amount)
    local color = 0
    for _, place in ipairs({ 65536, 256, 1 }) do
        local a, b = math.floor(fg / place) % 256, math.floor(bg / place) % 256
        color = color + math.floor(b + (a - b) * amount + 0.5) * place
    end
    return color
end

function M.highlights()
    local function hl(name)
        return api.nvim_get_hl(0, { name = name, link = false })
    end
    local bg = hl("Normal").bg or 0x000000
    local green = hl("MiniIconsGreen").fg or 0x1DB954
    for level = 0, 16 do
        local color = blend(green, bg, 0.15 + 0.85 * level / 16)
        api.nvim_set_hl(0, "SpotifyProgress" .. level, { fg = color, bg = bg })
    end
end

local function truncate(text, width)
    text = vim.fn.strtrans(text or "")
    if vim.fn.strdisplaywidth(text) <= width then
        return text
    end
    local result = ""
    for _, char in ipairs(vim.fn.split(text, "\\zs")) do
        if vim.fn.strdisplaywidth(result .. char) > width - 1 then
            break
        end
        result = result .. char
    end
    return result .. "…"
end

local function time(ms)
    local seconds = math.floor(ms / 1000)
    return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function wrap(text, width)
    local lines, line = {}, ""
    for word in vim.fn.strtrans(text or ""):gmatch("%S+") do
        if line ~= "" and vim.fn.strdisplaywidth(line .. " " .. word) <= width then
            line = line .. " " .. word
        else
            if line ~= "" then
                lines[#lines + 1] = line
            end
            line = ""
            -- Oversized words also split by display cells; never cut UTF-8 bytes.
            for _, char in ipairs(vim.fn.split(word, "\\zs")) do
                if vim.fn.strdisplaywidth(line .. char) > width then
                    lines[#lines + 1] = line
                    line = ""
                end
                line = line .. char
            end
        end
    end
    lines[#lines + 1] = line
    return lines
end

function M.rows(width)
    local client = require("spotify")
    local state = client.get()
    local label = " 󰓇 " .. (not state.logged_in and " - login" or state.error and " - error"
        or not state.name and (state.is_playing and " - unavailable" or " - idle") or "")
    local rows = { { { label, "Title" } } }
    if state.error then
        rows[#rows + 1] = { { " " .. truncate(state.error:gsub("^Spotify: ", ""), width - 1), "DiagnosticError" } }
    end
    if not state.name then
        return rows
    end
    for _, line in ipairs(wrap(state.name, width - 1)) do
        rows[#rows + 1] = { { " " .. line, "Normal" } }
    end
    rows[#rows + 1] = { { " " .. truncate(state.artist, width - 1), "Comment" } }
    local progress, cells = client.progress(), width - 4
    local fraction = state.duration_ms > 0 and progress / state.duration_ms or 0
    local bar = { { " ", "Normal" }, { "╶", "SpotifyProgress" .. (fraction > 0 and 16 or 0) } }
    for cell = 1, cells do
        local level = math.floor(math.max(0, math.min(1, fraction * cells - cell + 1)) * 16 + 0.5)
        bar[#bar + 1] = { "─", "SpotifyProgress" .. level }
    end
    bar[#bar + 1] = { "╴", "SpotifyProgress" .. (fraction >= 1 and 16 or 0) }
    local progress_row = #rows + 1
    rows[#rows + 1] = bar
    rows[#rows + 1] = { { " " .. truncate(time(progress) .. " / " .. time(state.duration_ms)
        .. (state.stale and " stale" or state.is_playing and " playing" or " paused"), width - 1), "Comment" } }
    return rows, progress_row
end

return M
