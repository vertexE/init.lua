local M = {}

local segments = require("ui.winbar.segments")
local store = require("ui.winbar.store")
local ui = require("ui.winbar.draw")

--- which filetypes to never draw statusbar in
--- @type string[]
local EXCLUDE_FNAME = { "dbui", "COMMIT_EDITMSG" }

M.draw_tabline = function()
    return ui.winbar(store.content("tabline"))
end

M.draw_winbar = function()
    return ui.winbar(store.content("winbar"))
end

M.draw_focused_winbar = function()
    return ui.winbar(store.content("winbar", true))
end

local draw_loop = function()
    local timer = vim.uv.new_timer()
    timer:start(
        0,
        3000,
        vim.schedule_wrap(function()
            vim.cmd("redrawstatus")
        end)
    )
end

--- @class statusbar.DrawRequest
--- @field inactive integer[] all other drawable wins
--- @field active integer the win the cursor is in

--- find which windows we want to draw
--- @return statusbar.DrawRequest
local get_drawable_wins = function()
    local wins = vim.api.nvim_list_wins()
    local cursor_winr = vim.api.nvim_get_current_win()
    local tab = vim.api.nvim_get_current_tabpage()

    --- @type statusbar.DrawRequest
    local request = {
        inactive = {},
        active = -1,
    }

    for _, winr in ipairs(wins) do
        local buf = vim.api.nvim_win_get_buf(winr)
        local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")
        local can_draw = not vim.api.nvim_win_get_config(winr).zindex -- no floating
            and tab == vim.api.nvim_win_get_tabpage(winr) -- no need to draw if it's no in the current tab
            and vim.bo[buf].buftype == "" -- normal buffer
            -- and not vim.tbl_contains(EXCLUDE_FT, vim.bo[buf].filetype)
            and not vim.tbl_contains(EXCLUDE_FNAME, name)
            and not vim.wo[winr].diff -- not in diff mode

        if can_draw and cursor_winr == winr then
            request.active = winr
        elseif can_draw then
            table.insert(request.inactive, winr)
        end
    end

    return request
end

M.setup = function()
    segments.setup()
    vim.api.nvim_create_autocmd({ "VimEnter", "BufWinEnter", "WinEnter" }, {
        group = vim.api.nvim_create_augroup("user.winbar", { clear = true }),
        desc = "Attach bars",
        callback = function(args)
            -- always refresh tabline
            vim.o.tabline = "%{%v:lua.require'ui.winbar.bar'.draw_tabline()%}"

            if vim.bo[args.buf].buftype ~= "" then
                return -- skip running on unsupported buffers
            end

            local to_draw = get_drawable_wins()
            if vim.api.nvim_win_is_valid(to_draw.active) then
                vim.wo[to_draw.active].winbar = "%{%v:lua.require'ui.winbar.bar'.draw_focused_winbar()%}"
            end

            for _, inactive_win in ipairs(to_draw.inactive) do
                vim.wo[inactive_win].winbar = "%{%v:lua.require'ui.winbar.bar'.draw_winbar()%}"
            end
        end,
    })
    draw_loop()
end

return M
