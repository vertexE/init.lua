local M = {}

M.write_vlines_as_content = function(bufnr, ns, v_lines)
    local lines = {}
    for _, vline in ipairs(v_lines) do
        local line = ""
        for _, chunk in ipairs(vline) do
            line = line .. (chunk[1] or ""):gsub("[\r\n]", "")
        end
        table.insert(lines, line)
    end

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

    for linenr, vline in ipairs(v_lines) do
        local col = 0
        for _, chunk in ipairs(vline) do
            local text, hl_group = chunk[1], chunk[2]
            if text and #text > 0 and hl_group then
                -- Add extmark for this chunk
                vim.api.nvim_buf_set_extmark(bufnr, ns, linenr - 1, col, {
                    end_col = col + #text,
                    hl_group = hl_group,
                    -- Add other extmark options as needed
                })
                col = col + #text
            elseif text then
                col = col + #text
            end
        end
    end
end

return M
