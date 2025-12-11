local M = {}

local tbl = require("tbl")

local severity_to_word = {
    [vim.diagnostic.severity.ERROR] = "Error",
    [vim.diagnostic.severity.WARN] = "Warn",
    [vim.diagnostic.severity.INFO] = "Info",
    [vim.diagnostic.severity.HINT] = "Hint",
}

local ns = vim.api.nvim_create_namespace("user.diagnostic.inline")

--- shrink diagnostic message to size of window as best as we can
--- fallback on wrapping the diagnostic message at 30 characters, without splitting words
local WRAP_WORDS_CHAR_LIMIT = 40

--- wrap words to meed wrap_at limit, adding whitespace padding to the end
--- of each new line.
--- @param lines string[] multiline string, broken up by \n
--- @param wrap_at number maximum characters per line
--- @return string[] adjusted multiline string
local word_wrap_aligned = function(lines, wrap_at)
    local result = {}
    for i, line in ipairs(lines) do
        local offset = i == 1 and 3 or 0
        if #line <= wrap_at then
            table.insert(result, line .. string.rep(" ", wrap_at - #line - offset))
            offset = 0
        else
            -- wrap long lines at word boundaries
            local current = ""
            for word in line:gmatch("%S+") do
                if #current == 0 then
                    local prefix = #result >= 1 and string.rep(" ", 3) or ""
                    current = prefix .. word
                elseif #current + 1 + offset + #word < wrap_at then
                    current = current .. " " .. word
                else
                    table.insert(result, current .. string.rep(" ", wrap_at - #current - offset))
                    offset = 0
                    current = string.rep(" ", 3) .. word
                end
            end
            if #current > 0 then
                table.insert(result, current .. string.rep(" ", wrap_at - #current - offset))
                offset = 0
            end
        end
    end
    return result
end

local draw_diagnostics_summary = function(bufnr, diagnostics)
    local diagnostics_by_ln = tbl.group_by_selector(diagnostics, function(diagnostic)
        return diagnostic.lnum
    end)

    --- @type table<integer, table<table<string,string>>>
    local vline_by_lnum = {}

    for lnum, diagnostics_for_line in pairs(diagnostics_by_ln) do
        table.sort(diagnostics_for_line, function(diagA, diagB)
            return diagA.severity < diagB.severity
        end)
        --- @type vim.Diagnostic
        local diagnostic = diagnostics_for_line[1]
        local hl_key = severity_to_word[diagnostic.severity]
        local hl_no_bg = string.format("Diagnostic%sTextNoBg", hl_key)
        local hl_with_bg = string.format("Diagnostic%sTextWithBg", hl_key)
        vline_by_lnum[lnum] = {
            { "     ", "TextDimmer" },
            { "", hl_no_bg },
            { "  " .. tostring(#diagnostics_for_line) .. " ", hl_with_bg },
            { "", hl_no_bg },
        }
    end

    for lnum, vline in pairs(vline_by_lnum) do
        vim.api.nvim_buf_set_extmark(bufnr, ns, lnum, 0, {
            virt_text = vline,
            virt_text_pos = "eol",
        })
    end
end

--- @param bufnr integer
--- @param diagnostics table<vim.Diagnostic>
--- @param cl_zero integer - 0 based indexed position of cursor
local draw_diagnostics_on_line = function(bufnr, diagnostics, cl_zero)
    -- we'll want to show all of the diagnostic messages
    -- on the current line, there can be many
    local line_len = 0
    local line = vim.api.nvim_buf_get_lines(bufnr, cl_zero, cl_zero + 1, false)[1]
    local total_lines = vim.api.nvim_buf_line_count(bufnr)
    if line then
        line_len = #line
    end

    -- 1 determine the width of my message
    local winr = vim.api.nvim_get_current_win()
    local win_width = vim.api.nvim_win_get_width(winr)
    local wrap_word_on_len = math.min(win_width - line_len, WRAP_WORDS_CHAR_LIMIT)

    local vlines = {}
    for i, diagnostic in ipairs(diagnostics) do
        local msg = word_wrap_aligned(vim.split(diagnostic.message, "\n"), wrap_word_on_len)
        local hl_key = severity_to_word[diagnostic.severity]
        local hl_no_bg = string.format("Diagnostic%sTextNoBg", hl_key)
        local hl_with_bg = string.format("Diagnostic%sTextWithBg", hl_key)
        for j, msg_segment in ipairs(msg) do
            local vline = (i == 1 and j == 1) and { { "     ", "TextDimmer" }, { "", hl_no_bg } }
                or { { string.rep(" ", 7), "TextDimmer" } }
            table.insert(vline, { (j == 1 and " ● " or "") .. msg_segment, hl_with_bg })
            if i == #diagnostics and j == #msg then
                table.insert(vline, { "", hl_no_bg })
            end
            table.insert(vlines, vline)
        end
    end

    for i, vline in ipairs(vlines) do
        if cl_zero + i < total_lines then
            vim.api.nvim_buf_set_extmark(bufnr, ns, cl_zero + i - 1, 0, {
                virt_text = vline,
                virt_text_win_col = line_len + 1,
            })
        elseif cl_zero + i == total_lines then
            -- FIXME: this isn't a great solution -- prefer to squish or do something else...
            vim.api.nvim_buf_set_extmark(bufnr, ns, cl_zero + i - 1, 0, {
                virt_text = tbl.merge(vline, { { "+++", "TextDimmer" } }),
                virt_text_win_col = line_len + 1,
            })
        end
    end
end

--- @param bufnr integer
local draw_diagnostics = function(bufnr)
    if bufnr ~= vim.api.nvim_get_current_buf() then
        -- only render in the current buffer
        return
    end

    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    local diagnostics = vim.diagnostic.get(bufnr)
    local cl = vim.fn.getpos(".")[2] - 1

    --- @type table<vim.Diagnostic>
    local line_diagnostics = {}
    --- @type table<vim.Diagnostic>
    local other_diagnostics = {}
    for _, diagnostic in ipairs(diagnostics) do
        if diagnostic.lnum == cl then
            table.insert(line_diagnostics, diagnostic)
        else
            table.insert(other_diagnostics, diagnostic)
        end
    end

    if #line_diagnostics > 0 then
        draw_diagnostics_on_line(bufnr, line_diagnostics, cl)
        return
    end
    -- elseif #line_diagnostics == 0 and is_cl_move_event and have_drawn_in_buffer[bufnr] then
    --     -- reduce unnecessary redraws of diagnostics
    --     return
    -- end

    if #other_diagnostics > 0 then
        draw_diagnostics_summary(bufnr, other_diagnostics)
        return
    end
end

M.setup = function()
    vim.api.nvim_create_autocmd({ "InsertEnter", "BufWritePost" }, {
        callback = function(ev)
            vim.api.nvim_buf_clear_namespace(ev.buf, ns, 0, -1)
        end,
    })

    vim.api.nvim_create_autocmd("CursorMoved", {
        callback = function(ev)
            draw_diagnostics(ev.buf)
        end,
    })

    vim.api.nvim_create_autocmd("DiagnosticChanged", {
        callback = function(ev)
            draw_diagnostics(ev.buf)
        end,
    })
end

return M
