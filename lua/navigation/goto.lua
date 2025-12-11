local M = {}
local H = {}

-- TODO: when opening menu, cursor should appear on current file (if I'm in that file) / the last accessed file
-- TODO: extmark text over buffer to display file name, symbol, if it's edited, Comment hl on full path, file size, etc.
--       ^the above would also require an autocommand for when we switch modes to know when to show/hide tasks

local fs = require("fs")

local LOCATION = "~/.cache/nvim/user-goto"
local FILE = "_gotos.txt"

--- @class goto.File
--- @field path string
--- @field cl integer cursor line

--- @return string
local filepath = function()
    return vim.fn.expand(LOCATION .. "/" .. vim.fn.fnamemodify("", ":p:h"):gsub("/", "_") .. FILE)
end

--- @param line string
--- @return goto.File|nil
local parse_line = function(line)
    local path, cl = string.match(line, "^(.-):(%d+)$")
    if path and cl then
        return { path = path, cl = cl }
    end
end

local state = {
    should_refresh_cached_goto_list = true,
    cursor_pos_by_buf = {},
}

--- add the current buffer to the file list
M.add = function()
    local bufnr = vim.api.nvim_get_current_buf()
    if not H.is_supported_buf(bufnr) then
        vim.notify("cannot add invalid buffer", vim.log.levels.WARN, {})
        return
    end
    local name = vim.api.nvim_buf_get_name(bufnr)
    local fpath = vim.fn.fnamemodify(name, ":p:.")
    local cl = vim.fn.getpos(".")[2]
    fs.append_line(filepath(), string.format("%s:%d", fpath, cl))
    state.should_refresh_cached_goto_list = true
end

--- check if goto supports this buf type
--- @param bufnr integer
--- @return boolean
H.is_supported_buf = function(bufnr)
    return vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_get_option_value("buftype", { buf = bufnr }) == ""
end

--- sync state of active goto file to the passed in state
--- @param files table<goto.File>
H.sync = function(files)
    local content = ""
    for _, file in ipairs(files) do
        content = content .. string.format("%s:%d\n", file.path, file.cl)
    end
    fs.write(filepath(), content)
    state.should_refresh_cached_goto_list = true
end

--- goto the provided index and open in the corresponding window
--- @param file goto.File|nil
--- @param winr integer
H.open = function(file, winr)
    if file == nil then
        return
    end
    vim.api.nvim_set_current_win(winr)

    local bufs = vim.api.nvim_list_bufs()
    local bufnr = vim.iter(bufs):find(function(buf)
        local name = vim.api.nvim_buf_get_name(buf)
        local fpath = vim.fn.fnamemodify(name, ":p:.")
        return fpath == file.path
    end)

    if bufnr ~= nil then
        vim.api.nvim_win_set_buf(winr, bufnr)
    else
        vim.cmd("edit " .. file.path)
    end
    vim.cmd(string.format("normal! %dggzz", file.cl))
    state.should_refresh_cached_goto_list = false
end

--- @type string|nil
local cached_gotos = ""

--- quickly open a specific saved goto
--- @param i integer 1 based index
M.quick_open = function(i)
    if state.should_refresh_cached_goto_list then
        cached_gotos, _ = fs.read(filepath())
    end
    if cached_gotos ~= nil then
        local lines = vim.split(cached_gotos, "\n")
        local line = lines[i]
        if line ~= nil then
            local file = parse_line(line)
            H.open(file, 0)
        else
            vim.notify("invalid position", vim.log.levels.WARN, {})
        end
    end
end

--- open an editable float
M.menu = function()
    local winr = vim.api.nvim_get_current_win()
    local editor_width = vim.o.columns
    local editor_height = vim.o.lines
    local width = math.floor(0.7 * editor_width)
    local height = math.floor(0.32 * editor_height)
    local row = (editor_height - height) / 2
    local col = (editor_width - width) / 2

    local float_buf = vim.api.nvim_create_buf(false, true)
    local float_winr = vim.api.nvim_open_win(float_buf, true, {
        title = vim.fn.fnamemodify("", ":p:h"),
        relative = "editor",
        row = row,
        col = col,
        width = width,
        height = height,
        style = "minimal",
        border = "rounded",
    })
    vim.api.nvim_set_option_value("buftype", "nofile", { buf = float_buf, scope = "local" })
    vim.wo[float_winr].signcolumn = "yes"

    vim.cmd("edit " .. filepath())

    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
        buffer = float_buf,
        group = vim.api.nvim_create_augroup("user.goto.notif", { clear = true }),
        callback = function()
            vim.notify("saved!")
        end,
    })

    vim.keymap.set("n", "<enter>", function()
        local line = vim.api.nvim_get_current_line()
        local file = parse_line(line)
        H.open(file, winr)
        if vim.api.nvim_buf_is_valid(float_buf) then
            vim.api.nvim_buf_delete(float_buf, { force = true })
        end
    end, { buffer = float_buf })

    vim.keymap.set("n", "q", function()
        if vim.api.nvim_buf_is_valid(float_buf) then
            vim.api.nvim_buf_delete(float_buf, { force = true })
        end
    end, { buffer = float_buf })
end

M.setup = function()
    local dir = vim.fn.expand(LOCATION)
    if vim.fn.isdirectory(dir) == 0 then
        vim.fn.mkdir(dir, "p")
    end

    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        group = vim.api.nvim_create_augroup("user.goto.sync_cursor_pos", { clear = true }),
        callback = function(ev)
            state.cursor_pos_by_buf[ev.buf] = vim.fn.getpos(".")[2]
        end,
    })

    vim.api.nvim_create_autocmd({ "BufLeave", "VimLeave" }, {
        group = vim.api.nvim_create_augroup("user.goto.sync_cursor", { clear = true }),
        callback = vim.schedule_wrap(function(ev)
            if not vim.api.nvim_buf_is_valid(ev.buf) then
                return
            end
            local content, _ = fs.read(filepath())
            local name = vim.api.nvim_buf_get_name(ev.buf)
            local fpath = vim.fn.fnamemodify(name, ":p:.")
            local files = vim.iter(vim.split(content or "", "\n"))
                :map(function(line)
                    local file = parse_line(line)
                    -- update the cursor pos in the active project file
                    if file and fpath == file.path and state.cursor_pos_by_buf[ev.buf] then
                        file.cl = state.cursor_pos_by_buf[ev.buf]
                    end

                    return file
                end)
                :totable()
            H.sync(files)
        end),
    })

    vim.api.nvim_create_autocmd({ "DirChanged" }, {
        group = vim.api.nvim_create_augroup("user.goto.dir", { clear = true }),
        callback = function()
            state.should_refresh_cached_goto_list = true
        end,
    })
end

return M
