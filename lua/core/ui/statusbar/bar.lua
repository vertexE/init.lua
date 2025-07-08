local M = {}

local segments = require("core.ui.statusbar.segments")
local store = require("core.ui.statusbar.store")
local ui = require("core.ui.statusbar.draw")

--- which filetypes to never draw statusbar in
--- @type string[]
local EXCLUDE_FNAME = { "dbui" }

M.draw_all = function()
    store.tick()
    return ui.winbar(store.content())
end

M.draw_simple = function()
    store.tick()
    return ui.winbar(store.content("filepath"))
end

local draw_loop = function()
    local timer = vim.uv.new_timer()
    timer:start(
        0,
        30000,
        vim.schedule_wrap(function()
            vim.cmd("redrawstatus")
        end)
    )
end

--- @class statusbar.DrawRequest
--- @field simple integer[] all the winr to draw a simple view in
--- @field main integer the main winr to draw in

--- find which windows we want to draw
--- @return statusbar.DrawRequest
local get_drawable_wins = function()
    local wins = vim.api.nvim_list_wins()
    local current = vim.api.nvim_get_current_win()

    --- @type statusbar.DrawRequest
    local request = {
        simple = {},
        main = -1,
    }

    for _, winr in ipairs(wins) do
        local buf = vim.api.nvim_win_get_buf(winr)
        local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")
        local can_draw = not vim.api.nvim_win_get_config(winr).zindex -- no floating
            and vim.bo[buf].buftype == "" -- normal buffer
            -- and not vim.tbl_contains(EXCLUDE_FT, vim.bo[buf].filetype)
            and not vim.tbl_contains(EXCLUDE_FNAME, name)
            and not vim.wo[winr].diff -- not in diff mode

        if can_draw and winr == current then
            request["main"] = winr
        elseif can_draw and winr ~= current then
            table.insert(request["simple"], winr)
        end -- else we ignore that window and draw nothing
    end

    return request
end

M.setup = function()
    segments.setup()
    vim.api.nvim_create_autocmd({ "VimEnter", "BufWinEnter", "WinEnter" }, {
        group = vim.api.nvim_create_augroup("user/statusbar/winbar", { clear = true }),
        desc = "Attach winbar",
        callback = function(args)
            if vim.bo[args.buf].buftype ~= "" then
                return -- no need to recalculate for wins that aren't normal buffers
            end

            vim.o.showtabline = 0
            local to_draw = get_drawable_wins()

            if vim.api.nvim_win_is_valid(to_draw.main) then
                vim.wo[to_draw.main].winbar = "%{%v:lua.require'core.ui.statusbar.bar'.draw_all()%}"
            end

            for _, simple_win in ipairs(to_draw.simple) do
                vim.wo[simple_win].winbar = "%{%v:lua.require'core.ui.statusbar.bar'.draw_simple()%}"
            end
        end,
    })
    draw_loop()
end

return M
