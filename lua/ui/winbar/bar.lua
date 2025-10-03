local M = {}

local segments = require("ui.winbar.segments")
local store = require("ui.winbar.store")
local ui = require("ui.winbar.draw")

--- which filetypes to never draw statusbar in
--- @type string[]
local EXCLUDE_FNAME = { "dbui", "COMMIT_EDITMSG" }

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
    local tab = vim.api.nvim_get_current_tabpage()

    --- @type statusbar.DrawRequest
    local request = {
        simple = {},
        main = -1,
    }

    local top_right_col = -1
    for _, winr in ipairs(wins) do
        local buf = vim.api.nvim_win_get_buf(winr)
        local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")
        local can_draw = not vim.api.nvim_win_get_config(winr).zindex -- no floating
            and tab == vim.api.nvim_win_get_tabpage(winr) -- no need to draw if it's no in the current tab
            and vim.bo[buf].buftype == "" -- normal buffer
            -- and not vim.tbl_contains(EXCLUDE_FT, vim.bo[buf].filetype)
            and not vim.tbl_contains(EXCLUDE_FNAME, name)
            and not vim.wo[winr].diff -- not in diff mode

        local pos = vim.api.nvim_win_get_position(winr)
        local row, col = pos[1], pos[2]

        if can_draw and row == 0 and col > top_right_col then -- found a new winr that is the largest
            top_right_col = col
            if request.main >= 0 then
                table.insert(request.simple, request.main)
                request.main = winr
            else
                request.main = winr
            end
        elseif can_draw then -- default case, these are simple windows
            table.insert(request.simple, winr)
        end
    end

    return request
end

M.setup = function()
    segments.setup()
    vim.api.nvim_create_autocmd({ "VimEnter", "BufWinEnter", "WinEnter" }, {
        group = vim.api.nvim_create_augroup("user.winbar", { clear = true }),
        desc = "Attach winbar",
        callback = function(args)
            if vim.bo[args.buf].buftype ~= "" then
                return -- no need to recalculate for wins that aren't normal buffers
            end
            local to_draw = get_drawable_wins()

            if vim.api.nvim_win_is_valid(to_draw.main) then
                vim.wo[to_draw.main].winbar = "%{%v:lua.require'ui.winbar.bar'.draw_all()%}"
            end

            for _, simple_win in ipairs(to_draw.simple) do
                vim.wo[simple_win].winbar = "%{%v:lua.require'ui.winbar.bar'.draw_simple()%}"
            end
        end,
    })
    draw_loop()
end

return M
