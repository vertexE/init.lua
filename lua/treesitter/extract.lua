local M = {}

-- NOTE: use <span class="space">&nbsp;</span> as spaces between chars, manually inserted for now...

--- Get hex color from highlight group
--- @param hl_group string
--- @return string|nil, string|nil
local function get_hl_colors(hl_group)
    local hl = vim.api.nvim_get_hl(0, { name = hl_group })
    local fg = hl.fg and string.format("#%06x", hl.fg) or nil
    local bg = hl.bg and string.format("#%06x", hl.bg) or nil
    return fg, bg
end

--- Check if a node is a leaf (has no children)
--- @param node TSNode
--- @return boolean
local function is_leaf(node)
    return node:child_count() == 0
end

--- Extract highlights from treesitter nodes
--- @param bufnr integer
--- @param start_line integer 0 based indexing (line 1 is val 0)
--- @param end_line integer 0 based indexing (line 1 is val 0)
--- @return table
M.highlights = function(bufnr, start_line, end_line)
    local results = {}
    local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line + 1, false)

    local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
    if not ok or not parser then
        return results
    end

    local trees = parser:parse()
    if not trees or #trees == 0 then
        return results
    end

    local root = trees[1]:root()

    local function walk(node)
        -- Only process leaf nodes to avoid duplicates
        if is_leaf(node) then
            local start_row, start_col, end_row, end_col = node:range()

            if start_row >= start_line and start_row <= end_line then
                local text = vim.treesitter.get_node_text(node, bufnr)
                if node:type() == "//" then -- fix Rust issue
                    local line = lines[start_row + 1 - start_line]
                    text = line
                end
                local inspect = vim.inspect_pos(bufnr, start_row, start_col)

                local hl_group = nil
                if inspect.treesitter and #inspect.treesitter > 0 then
                    hl_group = inspect.treesitter[#inspect.treesitter].hl_group_link
                end

                if hl_group then
                    local fg, bg = get_hl_colors(hl_group)
                    table.insert(results, {
                        text = text,
                        hl_group = hl_group,
                        fg = fg,
                        bg = bg,
                        row = start_row,
                        col = start_col,
                        end_row = end_row,
                        end_col = end_col,
                    })
                end
            end
        end

        for child in node:iter_children() do
            walk(child)
        end
    end

    walk(root)

    -- sort results by row and column
    table.sort(results, function(a, b)
        if a.row == b.row then
            return a.col < b.col
        end
        return a.row < b.row
    end)

    return results
end

--- Escape HTML special characters
--- @param text string
--- @return string
local function escape_html(text)
    local s, _ = text:gsub("&", "&amp;")
        :gsub("<", "&lt;")
        :gsub(">", "&gt;")
        :gsub('"', "&quot;")
        :gsub("'", "&#39;")
        :gsub("{", "&#123;")
        :gsub("}", "&#125;")
    return s
end

--- Sanitize class name (remove invalid CSS characters)
--- @param name string
--- @return string
local sanitize_class = function(name)
    local s, _ = name:gsub("[@.]", "")
    return s
end

---@param el string
---@param class string
---@param content string
---@param id ?string
---@return string
local wrap = function(el, class, content, id)
    if id then
        return string.format('<%s id="%s" class="%s">%s</%s>', el, id, class, content, el)
    end

    return string.format('<%s class="%s">%s</%s>', el, class, content, el)
end

--- Convert highlights to HTML
--- @param bufnr integer
--- @param start_line integer 0 based indexing
--- @param end_line integer 0 based indexing
--- @return string
M.as_html = function(bufnr, start_line, end_line)
    local highlights = M.highlights(bufnr, start_line, end_line)
    local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line + 1, false)

    if #highlights == 0 then
        return ""
    end

    local hl_styles = {}
    for _, item in ipairs(highlights) do
        if item.hl_group and not hl_styles[item.hl_group] then
            hl_styles[item.hl_group] = {
                fg = item.fg,
                bg = item.bg,
            }
        end
    end

    local style_lines = {
        "<style>",
        ".line {",
        "  font-size: 0;",
        "}",
        ".space {",
        "  font-size: 1rem;",
        "}",
        ".code-block {",
        "  background-color: #1e1e2f;",
        "}",
        ".shrink {",
        "  transform: scale(0.8);",
        "  transition: transform 0.2s;",
        "}",
    }
    for hl_group, colors in pairs(hl_styles) do
        local class_name = sanitize_class(hl_group)
        local style_parts = {}
        table.insert(style_parts, "  font-size: 1rem;")
        if colors.fg then
            table.insert(style_parts, "  color: " .. colors.fg .. ";")
        end
        if colors.bg then
            table.insert(style_parts, "  background-color: " .. colors.bg .. ";")
        end
        if #style_parts > 0 then
            table.insert(style_lines, "." .. class_name .. " {")
            for _, style_part in ipairs(style_parts) do
                table.insert(style_lines, style_part)
            end
            table.insert(style_lines, "}")
        end
    end
    table.insert(style_lines, "</style>")

    local html_lines = {}
    local current_line = nil
    local line_tokens = {}
    local prev_token_end_col = nil

    for _, item in ipairs(highlights) do
        if current_line ~= nil and item.row ~= current_line then
            local line_html = '  <div class="line wrap-break-word whitespace-pre-wrap">\n'
            for _, token in ipairs(line_tokens) do
                line_html = line_html .. token
            end
            line_html = line_html .. "  </div>\n"
            table.insert(html_lines, line_html)
            line_tokens = {}
        end

        -- BUG: this doesn't quite work for when the token is of type string...?
        -- add spacing between tokens
        if type(prev_token_end_col) == "number" and prev_token_end_col < item.col and current_line == item.row then
            table.insert(
                line_tokens,
                string.format('    <span class="space">%s</span>', string.rep("&nbsp;", item.col - prev_token_end_col))
            )
        end

        -- add spacing at the start of each line
        if item.row ~= current_line then
            table.insert(
                line_tokens,
                string.format('    <span class="space">%s</span>', string.rep("&nbsp;", item.col))
            )
        end

        current_line = item.row
        prev_token_end_col = item.end_col

        local class = item.hl_group
                and (' class="' .. sanitize_class(item.hl_group) .. " text-base max-md:text-sm" .. '"')
            or ""

        local token_html = string.format("    <span%s>%s</span>\n", class, escape_html(item.text))
        table.insert(line_tokens, token_html)
    end

    --  append last line
    if #line_tokens > 0 then
        local line_html = '  <div class="line">\n'
        for _, token in ipairs(line_tokens) do
            line_html = line_html .. token
        end
        line_html = line_html .. "  </div>\n"
        table.insert(html_lines, line_html)
    end

    local rand = tostring(math.floor(math.random() * 50000))

    return table.concat(style_lines, "\n")
        .. wrap(
            "div",
            "relative mx-auto max-w-3xl w-full font-maple",
            wrap(
                "button",
                "absolute top-0 right-0 p-4 max-sm:p-2 max-sm:hidden",
                [[
<div class="relative">
  <div class="border-gray-500 border rounded p-2 absolute right-4.5"></div>
  <div class="border-gray-500 border rounded p-2 absolute right-3 top-1.5 bg-[#1e1e2f]"></div>
</div>
]],
                rand
            ) .. wrap("div", "code-block rounded p-4", table.concat(html_lines))
        )
        .. string.format(
            [[
<script>
  const btn = document.getElementById("%s");
  btn?.addEventListener("click", () => {
    btn.classList.add("shrink");
    btn.innerHTML =
      '<span class="p-2 bg-[#11111c] rounded text-muted">COPIED!</span>';
    navigator.clipboard.writeText(`%s`);
    setTimeout(() => {
      btn.classList.remove("shrink");
      btn.innerHTML = `
    <div class="relative">
      <div class="border-gray-500 border rounded p-2 absolute right-4.5"></div>
      <div class="border-gray-500 border rounded p-2 absolute right-3 top-1.5 bg-[#1e1e2f]"></div>
    </div>
        `;
    }, 800);
  });
</script>
]],
            rand,
            table.concat(lines, "\n")
        )
end

return M
