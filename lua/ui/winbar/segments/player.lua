local M = {}

local store = require("ui.winbar.store")

local FIFO_PIPE_UPDATE_TIME = 3000

local cache = {
    spotify = "",
}

local valid = {
    spotify = false,
}

local loading = {
    spotify = false,
}

local content = function()
    if valid.spotify then
        return #cache.spotify > 0 and { { "󰓇  ", "MiniIconsGreen" }, { cache.spotify, "@constant" } } or {}
    end

    -- this is a fifo pipe, will block until read/write pair go through
    if not loading.spotify then
        vim.system({ "cat", "/tmp/spyplayer-track" }, { text = true }, function(result)
            if #result.stdout > 0 then
                cache.spotify = result.stdout
                valid.spotify = true
                loading.spotify = false
            end
        end)
        loading.spotify = true
    end

    return #cache.spotify > 0 and { { "󰓇  ", "MiniIconsGreen" }, { cache.spotify, "@constant" } } or {}
end

M.setup = function()
    store.register_segment({
        name = "player",
        split = false,
        focused = content,
        default = content,
    })

    local timer = vim.uv.new_timer()
    timer:start(
        0,
        FIFO_PIPE_UPDATE_TIME,
        vim.schedule_wrap(function()
            valid.spotify = false
        end)
    )
end

return M
