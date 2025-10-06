local M = {}

M.select_content = function(s)
    -- Extract content inside the first triple backtick code block, newline after ``` is optional
    local content = s:match("```[^\n]*\n(.-)\n?```")
    return content or ""
end

return M
