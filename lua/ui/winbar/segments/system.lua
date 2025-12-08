local M = {}

local store = require("ui.winbar.store")

local CACHE_UPDATE_TIME = 20000
local cache = {
    battery_level = nil,
    battery_hl = "DiagnosticOk",
    battery_percent = "",
}
local valid = {
    battery_level = false,
}

--- @class statusbar.BatteryStatus
--- @field condition integer
--- @field discharging string
--- @field charging string

local battery_levels = {
    { condition = 95, discharging = " ", charging = " 󱐋", hl = "DiagnosticOk" },
    { condition = 90, discharging = " ", charging = " 󱐋", hl = "DiagnosticOk" },
    { condition = 80, discharging = " ", charging = " 󱐋", hl = "DiagnosticOk" },
    { condition = 70, discharging = " ", charging = " 󱐋", hl = "DiagnosticOk" },
    { condition = 60, discharging = " ", charging = " 󱐋", hl = "DiagnosticOk" },
    { condition = 50, discharging = " ", charging = " 󱐋", hl = "DiagnosticOk" },
    { condition = 40, discharging = " ", charging = " 󱐋", hl = "DiagnosticOk" },
    { condition = 30, discharging = " ", charging = " 󱐋", hl = "DiagnosticOk" },
    { condition = 20, discharging = " ", charging = " 󱐋", hl = "MiniIconsOrange" },
    { condition = 10, discharging = " ", charging = " 󱐋", hl = "MiniIconsOrange" },
    { condition = 0, discharging = " ", charging = " 󱐋", hl = "MiniIconsRed" },
}

--- @return string,string,string
local battery = function()
    if cache.battery_level ~= nil and valid.battery_level then
        return cache.battery_percent, cache.battery_level, cache.battery_hl
    end

    vim.system({ "pmset", "-g", "batt" }, { text = true }, function(cmd)
        local pattern = "%d%d?%d?%%" -- %d%d%d? matches 2 or 3 digits, %% matches the '%' character

        local segments = vim.split(cmd.stdout, " ", { trimempty = true })
        local percentage = ""
        for _, segment in ipairs(segments) do
            local start_pos, end_pos = string.find(segment, pattern)
            if start_pos and end_pos then
                percentage = string.sub(segment, start_pos, end_pos)
                percentage = string.sub(percentage, 1, #percentage - 1)
                break
            end
        end
        if #percentage == 0 then
            cache.battery_level = "󱚡 "
            cache.battery_hl = "MiniIconsYellow"
            valid.battery_level = true
            return
        end

        local remaining = tonumber(percentage)
        for _, level in ipairs(battery_levels) do
            if remaining >= level.condition then
                cache.battery_level = string.find(cmd.stdout, "discharging") and level.discharging or level.charging
                cache.battery_hl = level.hl
                cache.battery_percent = percentage .. "%% "
                valid.battery_level = true
                return
            end
        end
    end)

    return cache.battery_percent, cache.battery_level or "", cache.battery_hl or "DiagnosticOk"
end

M.setup = function()
    store.register_segment({
        name = "system",
        type = "tabline",
        split = false,
        content = function()
            local perecent, icon, hl = battery()
            return { { perecent, "@constant" }, { icon, hl } }
        end,
    })

    local timer = vim.uv.new_timer()
    timer:start(
        CACHE_UPDATE_TIME,
        CACHE_UPDATE_TIME,
        vim.schedule_wrap(function()
            valid.battery_level = false
        end)
    )
end

return M
