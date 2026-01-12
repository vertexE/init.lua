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
local WRAP_WORDS_CHAR_LIMIT = 45

--- wrap words to meed wrap_at limit, adding whitespace padding to the end
--- of each new line.
--- @param lines string[] multiline string, broken up by \n
--- @param wrap_at number maximum characters per line
--- @return string[] adjusted multiline string
local word_wrap_aligned = function(lines, wrap_at)
    local DOT_PREFIX_RENDER_OFFSET = 5
    local result = {}
    for i, line in ipairs(lines) do
        local offset = i == 1 and DOT_PREFIX_RENDER_OFFSET or 0 -- " ● " where the dot counts as 3 chars
        local prefix = #result >= 1 and " ┊ " or ""
        local prefixed_line = prefix .. line
        if #prefixed_line + offset < wrap_at then
            table.insert(result, prefixed_line .. string.rep(" ", wrap_at - #prefixed_line - offset))
            offset = 0
        else
            -- wrap long lines at word boundaries
            local current = ""
            for word in line:gmatch("%S+") do
                if #current == 0 then
                    current = prefix .. word
                elseif #current + 1 + offset + #word < wrap_at then
                    current = current .. " " .. word
                else
                    table.insert(result, current .. string.rep(" ", wrap_at - #current - offset))
                    offset = 0
                    current = " ┊ " .. word
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

--- Build virt_text for multi-colored diagnostic dots
--- @param diagnostics_for_line vim.Diagnostic[] diagnostics on the line
--- @param highest_severity string "Error" | "Warn" | "Info" | "Hint"
--- @param no_arrow ?boolean whether to also include   in the virtual text
--- @return table<table<string>> virt_text array
local build_dot_vtext_summary = function(diagnostics_for_line, highest_severity, no_arrow)
    local counts = { Error = 0, Warn = 0, Info = 0, Hint = 0 }
    for _, diag in ipairs(diagnostics_for_line) do
        local severity_word = severity_to_word[diag.severity]
        counts[severity_word] = counts[severity_word] + 1
    end

    local text_hl = string.format("Diagnostic%sTextWithBg", highest_severity)
    local border_hl = string.format("Diagnostic%sTextNoBg", highest_severity)

    local vtext = {}
    if no_arrow == nil or not no_arrow then
        table.insert(vtext, { "     ", "TextDimmer" })
    end

    table.insert(vtext, { "", border_hl })
    table.insert(vtext, { " ", text_hl })

    local bg_suffix = "On" .. highest_severity .. "Bg"

    local severities = {}
    for _, severity in pairs(severity_to_word) do
        if severity ~= highest_severity then
            table.insert(severities, severity)
        end
    end
    table.insert(severities, highest_severity)
    for _, severity in ipairs(severities) do
        if counts[severity] > 0 then
            local hl_group = "Diagnostic" .. severity .. "Dot" .. bg_suffix
            table.insert(vtext, { "●", hl_group })
        end
    end

    local total_count = #diagnostics_for_line
    table.insert(vtext, { " " .. tostring(total_count) .. " ", text_hl })
    table.insert(vtext, { "", border_hl })

    return vtext
end

--- diagnostics for the current file
--- @param bufnr integer
--- @return table virtual_text
M.file_summary = function(bufnr)
    local diagnostics = vim.diagnostic.get(bufnr)
    if #diagnostics == 0 then
        return {}
    end

    table.sort(diagnostics, function(diagA, diagB)
        return diagA.severity < diagB.severity
    end)
    --- @type vim.Diagnostic
    local diagnostic = diagnostics[1]
    local severity = severity_to_word[diagnostic.severity]
    return build_dot_vtext_summary(diagnostics, severity, true)
end

local draw_line_diagnostics_summary = function(bufnr, diagnostics)
    local buf_line_cnt = vim.api.nvim_buf_line_count(bufnr)
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
        local severity = severity_to_word[diagnostic.severity]
        local dot_vtext = build_dot_vtext_summary(diagnostics_for_line, severity)

        vline_by_lnum[lnum] = {}
        for _, vtext_elem in ipairs(dot_vtext) do
            table.insert(vline_by_lnum[lnum], vtext_elem)
        end
    end

    for lnum, vline in pairs(vline_by_lnum) do
        if lnum < buf_line_cnt then
            vim.api.nvim_buf_set_extmark(bufnr, ns, lnum, 0, {
                virt_text = vline,
                virt_text_pos = "eol",
                priority = 100,
            })
        end
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
        local _, tab_count = string.gsub(line, "\t", "")
        line_len = #line + (tab_count * 4)
    end

    -- 1 determine the width of my message
    local winr = vim.api.nvim_get_current_win()
    local win_width = vim.api.nvim_win_get_width(winr)
    local wrap_word_on_len = math.min(win_width - line_len, WRAP_WORDS_CHAR_LIMIT)

    local vlines = {}
    local hl_with_bg = ""
    local hl_no_bg = ""
    for i, diagnostic in ipairs(diagnostics) do
        local msg = word_wrap_aligned(vim.split(diagnostic.message, "\n"), wrap_word_on_len)
        local hl_key = severity_to_word[diagnostic.severity]
        hl_with_bg = string.format("Diagnostic%sTextWithBg", hl_key)
        hl_no_bg = string.format("Diagnostic%sTextNoBg", hl_key)
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
            local PREFIX_RENDERED_LENGTH = 4
            --- @type string[] of len 2
            local last_segment = vline[#vline]
            last_segment[1] = last_segment[1]:sub(1, #last_segment[1] - PREFIX_RENDERED_LENGTH)
                .. string.format("…+++")
            vim.api.nvim_buf_set_extmark(bufnr, ns, cl_zero + i - 1, 0, {
                virt_text = vline,
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

    if #other_diagnostics > 0 then
        draw_line_diagnostics_summary(bufnr, other_diagnostics)
        return
    end
end

local is_in_insert_mode = function()
    local mode = vim.api.nvim_get_mode().mode or ""
    return mode == "i" or mode == "ic" or mode == "ix"
end

M.setup = function()
    vim.api.nvim_create_autocmd({ "InsertEnter", "BufWritePost" }, {
        callback = function(ev)
            vim.api.nvim_buf_clear_namespace(ev.buf, ns, 0, -1)
        end,
    })

    vim.api.nvim_create_autocmd("CursorMoved", {
        callback = function(ev)
            if is_in_insert_mode() then
                return
            end
            draw_diagnostics(ev.buf)
        end,
    })

    vim.api.nvim_create_autocmd("DiagnosticChanged", {
        callback = function(ev)
            if is_in_insert_mode() then
                return
            end
            draw_diagnostics(ev.buf)
        end,
    })
end

return M
