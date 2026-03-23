local M = {}

local ns = vim.api.nvim_create_namespace("llm.conversations.mark")
local ns_chat = vim.api.nvim_create_namespace("llm.conversations.chat")
local floats = require("ui.floats")

--- @alias llm.MessageSource "claude"|"user"

--- @class llm.Message
--- @field content string
--- @field source llm.MessageSource

--- @class llm.Conversation
--- @field session_id string
--- @field buf integer
--- @field extmark_id integer ID for extmark when the conversation was opened
--- @field messages llm.Message[]
--- @field chat_buf integer
--- @field chat_win integer -- so we can control scrolling
--- @field textarea_buf integer
--- @field on_submit fun(prompt:string)

local state = {
    --- @type llm.Conversation[]
    conversations = {},
}

--- @param conversation llm.Conversation
local draw = function(conversation)
    -- clear
    vim.api.nvim_buf_set_lines(conversation.chat_buf, 0, -1, false, {})
    vim.api.nvim_buf_clear_namespace(conversation.chat_buf, ns_chat, 0, -1)
    --- [[ example conversation
    ---
    --- ┃ (LLM) > Good morning! Welcome to my bla bla baln.
    ---
    --- ┃ (You) > I want to know how
    ---
    --- ]]
    for _, message in ipairs(conversation.messages) do
        local row = vim.api.nvim_buf_line_count(conversation.chat_buf)
        vim.api.nvim_buf_set_lines(
            conversation.chat_buf,
            -1,
            -1,
            false,
            vim.split(string.rep(" ", 10) .. message.content, "\n")
        )
        local is_claude = message.source == "claude"
        vim.api.nvim_buf_set_extmark(conversation.chat_buf, ns_chat, row, 0, {
            virt_text = {
                { is_claude and "┃ (LLM) >" or "┃ (You) > ", is_claude and "MiniIconsOrange" or "MiniIconsGreen" },
            },
            virt_text_pos = "overlay",
        })
    end

    local last_line = vim.api.nvim_buf_line_count(conversation.chat_buf)
    vim.api.nvim_win_set_cursor(conversation.chat_win, { last_line, 0 })
end

---@param conversation llm.Conversation
---@param forward_to_agent fun(prompt:string)
local open_conversation = function(conversation, forward_to_agent)
    local editor_width = vim.o.columns
    local editor_height = vim.o.lines

    local width = math.floor(0.8 * editor_width)
    local chat_height = math.floor(0.35 * editor_height)
    local textarea_height = math.floor(0.10 * editor_height)
    local col = math.floor((editor_width - width) / 2)
    -- center the stacked pair vertically (1 row gap between them)
    local total_height = chat_height + 2 + textarea_height
    local chat_row = math.floor((editor_height - total_height) / 2)
    local textarea_row = chat_row + chat_height + 2

    local chat_bufnr, chat_winr = floats.open({
        title = "󰛄 claude",
        height = chat_height,
        width = width,
        row = chat_row,
        col = col,
        close_on_q = false,
        bo = { filetype = "markdown" },
        wo = { wrap = true, number = false, relativenumber = false },
    })

    local textarea_bufnr, textarea_winr = floats.open({
        title = " ask",
        height = textarea_height,
        width = width,
        row = textarea_row,
        col = col,
        close_on_q = false,
        bo = { filetype = "markdown", buftype = "nowrite" },
        wo = { wrap = true, number = false, relativenumber = false },
    })

    conversation.chat_win = chat_winr
    conversation.chat_buf = chat_bufnr
    conversation.textarea_buf = textarea_bufnr

    local close_all = function()
        if vim.api.nvim_buf_is_valid(chat_bufnr) then
            vim.api.nvim_buf_delete(chat_bufnr, { force = true })
        end
        if vim.api.nvim_buf_is_valid(textarea_bufnr) then
            vim.api.nvim_buf_delete(textarea_bufnr, { force = true })
        end
    end

    local toggle_focus = function()
        local cur = vim.api.nvim_get_current_win()
        vim.api.nvim_set_current_win(cur == chat_winr and textarea_winr or chat_winr)
    end

    vim.keymap.set("n", "q", close_all, { buffer = chat_bufnr })
    vim.keymap.set("n", "q", close_all, { buffer = textarea_bufnr })
    vim.keymap.set("n", "<esc>", close_all, { buffer = chat_bufnr })
    vim.keymap.set("n", "<esc>", close_all, { buffer = textarea_bufnr })
    vim.keymap.set({ "n", "i" }, "<tab>", toggle_focus, { buffer = chat_bufnr })
    vim.keymap.set({ "n", "i" }, "<tab>", toggle_focus, { buffer = textarea_bufnr })

    vim.keymap.set({ "n" }, "<enter>", function()
        local lines = vim.api.nvim_buf_get_lines(textarea_bufnr, 0, -1, false)
        local prompt = table.concat(lines, "\n")
        M.push_message(conversation.session_id, prompt, "user")
        -- TODO: add context (original buf)
        forward_to_agent(prompt)
        vim.api.nvim_buf_set_lines(textarea_bufnr, 0, -1, false, {})
    end, { buffer = textarea_bufnr })

    vim.api.nvim_set_current_win(textarea_winr)
    vim.cmd("startinsert!")

    draw(conversation)
end

--- @param session_id string conversation ID to open
--- @param buf integer buffer the conversation takes place
--- @param row integer 0-indexed line position
--- @param on_submit fun(prompt:string)
M.create_conversation = function(session_id, buf, row, on_submit)
    local extmark_id = vim.api.nvim_buf_set_extmark(buf, ns, row, 0, {
        virt_text = {
            { "", "CodeLensSeparator" },
            { "󰛄 claude", "CodeLensContentIcon" },
            { "", "CodeLensSeparator" },
        },
        virt_text_pos = "eol",
        priority = 300,
    })
    --- @type llm.Conversation
    local conversation = {
        session_id = session_id,
        buf = buf,
        extmark_id = extmark_id,
        chat_buf = -1,
        chat_win = -1,
        textarea_buf = -1,
        messages = {},
        on_submit = on_submit,
    }
    table.insert(state.conversations, conversation)

    open_conversation(conversation, on_submit)
end

--- find conversation by buf and row without opening
--- @param buf integer
--- @param row integer - 0 based indexing
--- @return llm.Conversation|nil
M.find_by_buf_line = function(buf, row)
    return vim.iter(state.conversations):find(function(c)
        local extmark = vim.api.nvim_buf_get_extmark_by_id(buf, ns, c.extmark_id, {})
        return extmark and extmark[1] == row and c.buf == buf
    end)
end

--- lookup conversation by buf and row
--- @param buf integer
--- @param row integer - 0 based indexing
M.open_by_buf_line = function(buf, row)
    local existing_conversation = vim.iter(state.conversations):find(function(conversation)
        local extmark = vim.api.nvim_buf_get_extmark_by_id(buf, ns, conversation.extmark_id, {})
        return extmark and extmark[1] == row and conversation.buf == buf
    end)

    if not existing_conversation then
        vim.notify("llm: cannot find conversation", vim.log.levels.ERROR)
        return
    end

    open_conversation(existing_conversation, existing_conversation.on_submit)
end

--- @param session_id string conversation ID
--- @param msg string llm agent message to push to the conversation
--- @param source llm.MessageSource llm agent message to push to the conversation
M.push_message = function(session_id, msg, source)
    local conversation = M.conversation(session_id)
    if not conversation then
        vim.notify("llm: failed to find conversation", vim.log.levels.ERROR)
        return
    end
    table.insert(conversation.messages, { content = msg, source = source })
    if conversation.chat_buf > 0 and vim.api.nvim_buf_is_valid(conversation.chat_buf) then
        draw(conversation)
    end
end

--- lookup a conversation by conversation ID
--- @param session_id string conversation ID
--- @return llm.Conversation|nil
M.conversation = function(session_id)
    return vim.iter(state.conversations):find(function(conversation)
        return conversation.session_id == session_id
    end)
end

return M
