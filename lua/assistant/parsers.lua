local M = {}

--- @class assistant.codex_event
--- @field type string
--- @field thread_id? string
--- @field item? { type?: string, text?: string }

M.select_content = function(s)
    -- Extract content inside the first triple backtick code block, newline after ``` is optional
    local content = s:match("```[^\n]*\n(.-)\n?```")
    return content or ""
end

--- @param stdout string
--- @return string|nil,string|nil
M.codex_output = function(stdout)
    local text = nil
    local thread_id = nil

    for _, line in ipairs(vim.split(stdout, "\n", { trimempty = true })) do
        local ok, event = pcall(vim.json.decode, line)
        --- @cast event assistant.codex_event|nil
        if ok and event then
            if event.type == "thread.started" then
                thread_id = event.thread_id
            elseif event.type == "item.completed" and event.item and event.item.type == "agent_message" then
                text = event.item.text or text
            end
        end
    end

    return text, thread_id
end

return M
