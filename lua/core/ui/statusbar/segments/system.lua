local M = {}

local store = require("core.ui.statusbar.store")

local CACHE_UPDATE_TIME = 20000
local cache = {
    battery_level = nil,
}
local valid = {
    battery_level = false,
}

--- @class statusbar.BatteryStatus
--- @field condition integer
--- @field discharging string
--- @field charging string

local battery_levels = {
    { condition = 95, discharging = " ", charging = " 󱐋" },
    { condition = 90, discharging = " ", charging = " 󱐋" },
    { condition = 80, discharging = " ", charging = " 󱐋" },
    { condition = 70, discharging = " ", charging = " 󱐋" },
    { condition = 60, discharging = " ", charging = " 󱐋" },
    { condition = 50, discharging = " ", charging = " 󱐋" },
    { condition = 40, discharging = " ", charging = " 󱐋" },
    { condition = 30, discharging = " ", charging = " 󱐋" },
    { condition = 20, discharging = " ", charging = " 󱐋" },
    { condition = 10, discharging = " ", charging = " 󱐋" },
    { condition = 0, discharging = " ", charging = " 󱐋" },
}

--- @return string
local battery = function()
    if cache.battery_level and valid.battery_level then
        return cache.battery_level
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
            cache.battery_level = "󰂑"
            valid.battery_level = true
            return
        end

        local remaining = tonumber(percentage)
        for _, level in ipairs(battery_levels) do
            if remaining >= level.condition then
                cache.battery_level = string.find(cmd.stdout, "discharging") and level.discharging or level.charging
                valid.battery_level = true
                return
            end
        end
    end)

    return cache.battery_level or ""
end

local hours_minutes = function()
    local current_time = os.date("%a %H:%M")
    return tostring(current_time)
end

M.setup = function()
    store.register_segment({
        name = "system",
        split = false,
        focused = function()
            return { { hours_minutes, "DiagnosticOk" }, { " ", "Comment" }, { battery, "DiagnosticOk" } }
        end,
        default = function()
            return { { hours_minutes, "DiagnosticOk" }, { " ", "Comment" }, { battery, "DiagnosticOk" } }
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
