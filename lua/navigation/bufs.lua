local M = {}

local float = require("ui.floats")
local symbols = require("symbols")
local tbl = require("tbl")

--- @type table<integer> list of buffers, ordered by recently opened
local buf_stack = {}

local bufs_by_recency = function()
    local bufs = {}
    for _, buf in ipairs(buf_stack) do
        if vim.api.nvim_buf_is_valid(buf) then
            table.insert(bufs, buf)
        end
    end

    return bufs
end

local rmv_buf = function(bufnr)
    for pos, _bufnr in ipairs(buf_stack) do
        if bufnr == _bufnr then
            table.remove(buf_stack, pos)
            return
        end
    end
end

local push_buf_history = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local name = vim.api.nvim_buf_get_name(bufnr)

    if vim.bo[bufnr].buflisted and vim.bo[bufnr].buftype == "" and name ~= "" then
        -- remove buf if exists in stack, then push to top of stack
        rmv_buf(bufnr)
        table.insert(buf_stack, 1, bufnr)
    end
end

--- @param bufnr integer
--- @return string,string
local buf_name = function(bufnr)
    local abs_file_path = vim.api.nvim_buf_get_name(bufnr)
    if abs_file_path == "" then
        return "[No Name]", ""
    end
    return vim.fn.fnamemodify(abs_file_path, ":.:t"), vim.fn.fnamemodify(abs_file_path, ":.:h")
end

local FILE_ICONS_CHAR_LEN = 2
local MODIFIED_SYMBOL_LEN = 2
local DIAGNOSTICS_MAX_WIDTH = 12

local longest_buf_name = function()
    local longest_open_buf_name = 0
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(bufnr) then
            local name, relative = buf_name(bufnr)
            local rendered_line_len = FILE_ICONS_CHAR_LEN
                + #(name .. relative)
                + MODIFIED_SYMBOL_LEN
                + DIAGNOSTICS_MAX_WIDTH

            if
                rendered_line_len > longest_open_buf_name
                and vim.bo[bufnr].buflisted
                and vim.bo[bufnr].buftype == ""
            then
                longest_open_buf_name = rendered_line_len
            end
        end
    end
    return longest_open_buf_name
end

-- TODO: I can just use the stack bro?
-- local buffers_by_recency = function ()
--
-- end

local virtual_diagnostics = function(bufnr)
    local hint = vim.diagnostic.get(bufnr, { severity = vim.diagnostic.severity.HINT })
    local info = vim.diagnostic.get(bufnr, { severity = vim.diagnostic.severity.INFO })
    local warn = vim.diagnostic.get(bufnr, { severity = vim.diagnostic.severity.WARN })
    local error = vim.diagnostic.get(bufnr, { severity = vim.diagnostic.severity.ERROR })

    local hint_symbol = symbols.severity_to_diagnostic_lvl(vim.diagnostic.severity.HINT)
    local info_symbol = symbols.severity_to_diagnostic_lvl(vim.diagnostic.severity.INFO)
    local warn_symbol = symbols.severity_to_diagnostic_lvl(vim.diagnostic.severity.WARN)
    local error_symbol = symbols.severity_to_diagnostic_lvl(vim.diagnostic.severity.ERROR)

    local vtext = {}

    if #hint > 0 then
        table.insert(vtext, { tostring(#hint) .. " " .. hint_symbol, "DiagnosticSignHint" })
    end
    if #info > 0 then
        table.insert(vtext, { tostring(#info) .. " " .. info_symbol, "DiagnosticSignInfo" })
    end
    if #warn > 0 then
        table.insert(vtext, { tostring(#warn) .. " " .. warn_symbol, "DiagnosticSignWarn" })
    end
    if #error > 0 then
        table.insert(vtext, { tostring(#error) .. " " .. error_symbol, "DiagnosticSignError" })
    end

    return vtext
end

local draw_menu = function(bufnr)
    local bufs = bufs_by_recency()
    local ns = vim.api.nvim_create_namespace("users.bufs.menu")
    local lines = tbl.rep({}, "", #bufs)

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

    for i, _bufnr in ipairs(bufs) do
        local name, relative = buf_name(_bufnr)
        local decoration = symbols.file_icon(_bufnr)
        local modified = vim.bo[_bufnr].modified and " [+] " or ""
        local diagnostics = virtual_diagnostics(_bufnr)

        vim.api.nvim_buf_set_extmark(bufnr, ns, i - 1, 0, {
            hl_mode = "combine",
            virt_text = tbl.merge({
                { decoration.icon, decoration.hl },
                { #relative > 0 and relative .. "/" or "", "TextDim" },
                { name, "Text" },
                { modified, "MiniIconsOrange" },
                { " ", "Comment" },
            }, diagnostics),
        })
    end

    return bufs
end

M.open = function()
    local target_winr = vim.api.nvim_get_current_win()
    local draw_bufnr, _ = float.open({
        title = " Buffers",
        height = 0.4,
        width = math.max(longest_buf_name() / vim.o.columns, 0.4),
        max_width = 80,
        bo = {
            bufhidden = "wipe",
        },
        wo = {
            cursorline = true,
        },
    })

    local rendered_bufs = draw_menu(draw_bufnr)

    -- hide cursor
    vim.cmd("hi Cursor blend=100")
    vim.api.nvim_create_autocmd({ "WinClosed", "WinLeave" }, {
        buffer = draw_bufnr,
        group = vim.api.nvim_create_augroup("user.nav.bufs.cursor", { clear = true }),
        once = true,
        callback = function()
            vim.cmd("hi Cursor blend=0")
        end,
    })

    -- keymaps
    vim.keymap.set("n", "<CR>", function()
        local line = vim.fn.line(".")
        if rendered_bufs[line] and vim.api.nvim_buf_is_valid(rendered_bufs[line]) then
            local target_buf = rendered_bufs[line]
            vim.api.nvim_set_current_win(target_winr)
            vim.api.nvim_set_current_buf(target_buf)
            -- close menu
            vim.api.nvim_buf_delete(draw_bufnr, { force = true })
        end
    end, { buffer = draw_bufnr })

    vim.keymap.set("n", "dd", function()
        local line = vim.fn.line(".")
        local bufs = bufs_by_recency()
        if bufs[line] and vim.api.nvim_buf_is_valid(bufs[line]) then
            local target_buf = bufs[line]

            if target_buf ~= draw_bufnr and #bufs > 1 then
                vim.api.nvim_buf_delete(target_buf, { force = true })
                draw_menu(draw_bufnr)
            end
        end
    end, { buffer = draw_bufnr })
end

M.setup = function()
    vim.api.nvim_create_autocmd({ "BufEnter" }, {
        group = vim.api.nvim_create_augroup("user.nav.bufs.sync", { clear = true }),
        callback = push_buf_history,
    })
end

return M
