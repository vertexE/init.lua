local api = vim.api
local M = {}
local ns = api.nvim_create_namespace("user.menu")

--- @class MenuProps
--- @field open_children fun(): boolean Open this item's children, if present.

--- @class MenuItem
--- @field label string
--- @field icon? string
--- @field on_select? fun(props: MenuProps) Runs before close for branches and after close for leaves.
--- @field children? MenuItem[]
--- @field keymap? string q and <Esc> are reserved for going back.
--- @field divider? boolean

--- @class MenuOpts
--- @field position "cursor"|"editor"
--- @field title? string
--- @field min_width? integer Minimum width in terminal cells for the top-level menu.
--- @field items MenuItem[]

local function has_children(item)
    return item.children and #item.children > 0
end

local function layout(width, height, position, origin, parent)
    local columns = vim.o.columns
    local rows = vim.o.lines - vim.o.cmdheight
    local row, col, zindex
    if parent then
        row, col = unpack(api.nvim_win_get_position(parent.win))
        local right = col + api.nvim_win_get_width(parent.win) + 2
        if right + width + 2 <= columns then
            col = right
        end
        zindex = api.nvim_win_get_config(parent.win).zindex + 1
    elseif position == "cursor" then
        local cursor = api.nvim_win_get_cursor(origin)
        local screen = vim.fn.screenpos(origin, cursor[1], cursor[2] + 1)
        row, col = screen.row, screen.curscol - 1
        if row + height + 2 > rows then
            row = screen.row - height - 3
        end
    else
        row = math.floor((rows - height - 2) / 2)
        col = math.floor((columns - width - 2) / 2)
    end

    return {
        relative = "editor",
        row = math.max(0, math.min(row, rows - height - 2)),
        col = math.max(0, math.min(col, columns - width - 2)),
        width = width,
        height = height,
        border = "rounded",
        style = "minimal",
        focusable = false,
        zindex = zindex,
    }
end

local function close(menu, all)
    local target = all and menu.origin or (menu.parent and menu.parent.win or menu.origin)
    if api.nvim_get_current_win() == menu.win and api.nvim_win_is_valid(target) then
        api.nvim_set_current_win(target)
    end
    repeat
        if api.nvim_win_is_valid(menu.win) then
            api.nvim_win_close(menu.win, true)
        end
        menu = menu.parent
    until not all or not menu
end

local function open_menu(items, position, origin, parent, title, min_width)
    local lines, dividers, hints = {}, {}, {}
    local width = math.max(min_width or 1, title and vim.fn.strdisplaywidth(title) or 1)
    for i, item in ipairs(items) do
        local line = " " .. item.label:gsub("%c", " ")
        if item.icon then
            line = " " .. item.icon .. line
        end
        local chevron = has_children(item) and " ›" or ""
        local keymap = item.keymap or ""
        if keymap ~= "" then
            chevron = chevron .. "  "
            hints[i] = { { chevron }, { keymap, "Comment" } }
        elseif chevron ~= "" then
            hints[i] = { { chevron } }
        end
        lines[i] = line
        width = math.max(width, vim.fn.strdisplaywidth(line .. chevron .. keymap))
        if item.divider then
            dividers[#dividers + 1] = i
        end
    end
    width = math.min(width, math.max(1, vim.o.columns - 2))
    local height = math.min(#lines + #dividers, math.max(1, vim.o.lines - vim.o.cmdheight - 2))

    local buf = api.nvim_create_buf(false, true)
    vim.bo[buf].bufhidden = "wipe"
    api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    for row, chunks in pairs(hints) do
        api.nvim_buf_set_extmark(buf, ns, row - 1, 0, {
            virt_text = chunks,
            virt_text_pos = "right_align",
            hl_mode = "combine",
        })
    end
    local rule = ("─"):rep(math.floor(width / vim.fn.strdisplaywidth("─")))
    for _, row in ipairs(dividers) do
        api.nvim_buf_set_extmark(buf, ns, row - 1, 0, {
            virt_lines = { { { rule, "FloatBorder" } } },
        })
    end

    local config = layout(width, height, position, origin, parent)
    config.title = title
    local win = api.nvim_open_win(buf, true, config)
    local menu = { win = win, origin = origin, parent = parent }
    vim.wo[win].wrap = false
    vim.wo[win].scrolloff = 0
    vim.wo[win].sidescrolloff = 0
    vim.wo[win].winblend = 0
    vim.wo[win].cursorline = true
    vim.wo[win].cursorlineopt = "line"
    vim.wo[win].winhighlight = "CursorLine:MenuSelection"

    local saved_cursor
    local function hide_cursor()
        if saved_cursor == nil then
            saved_cursor = vim.o.guicursor
            local prefix = saved_cursor == "" and "" or saved_cursor .. ","
            vim.o.guicursor = prefix .. "a:MenuHiddenCursor"
        end
    end
    local function restore_cursor()
        if saved_cursor ~= nil then
            vim.o.guicursor = saved_cursor
            saved_cursor = nil
        end
    end
    api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, { buffer = buf, callback = hide_cursor })
    api.nvim_create_autocmd({ "WinLeave", "BufLeave", "BufWipeout" }, { buffer = buf, callback = restore_cursor })
    hide_cursor()

    local function select(item)
        local branch = has_children(item)
        local child
        local function open_children()
            if not child and branch and api.nvim_get_current_win() == win then
                child = open_menu(item.children, position, origin, menu)
            end
            return child ~= nil
        end
        local props = { open_children = open_children }

        if not branch then
            close(menu, true)
            if item.on_select then
                item.on_select(props)
            end
            return
        end

        local ok, err = pcall(item.on_select or open_children, props)
        if not ok or not child then
            close(child or menu, true)
        end
        if not ok then
            error(err, 0)
        end
    end

    local function map(key, action)
        vim.keymap.set("n", key, action, { buffer = buf })
    end
    local function move(offset)
        local row = api.nvim_win_get_cursor(win)[1] + offset * vim.v.count1
        api.nvim_win_set_cursor(win, { math.max(1, math.min(row, #items)), 0 })
    end
    map("j", function() move(1) end)
    map("<Down>", function() move(1) end)
    map("<C-n>", function() move(1) end)
    map("k", function() move(-1) end)
    map("<Up>", function() move(-1) end)
    map("<C-p>", function() move(-1) end)
    map("<CR>", function() select(items[api.nvim_win_get_cursor(win)[1]]) end)
    for _, item in ipairs(items) do
        if item.keymap and item.keymap ~= "" then
            map(item.keymap, function() select(item) end)
        end
    end
    map("q", function() close(menu, false) end)
    map("<Esc>", function() close(menu, false) end)
    return menu
end

--- @param opts MenuOpts
--- @return integer? win
function M.open(opts)
    if #opts.items == 0 then
        return
    end
    api.nvim_set_hl(0, "MenuSelection", { default = true, bg = "#23382E" })
    api.nvim_set_hl(0, "MenuHiddenCursor", { blend = 100, nocombine = true })
    return open_menu(opts.items, opts.position, api.nvim_get_current_win(), nil, opts.title, opts.min_width).win
end

return M
