local M = {}

local UPPER_BOUND = 100000

--- @type table<integer, llm.request> all active requests' files
--- will be locked. Once the request is completed and removed
--- from this list, we will unlock those files.
local requests = {}

--- marks the request as complete, removing any locks on any files
--- @param req_id any
M.complete = function(req_id)
    local request = requests[req_id]
    if not request then
        return
    end

    requests[req_id] = nil

    local bufnr = vim.api.nvim_get_current_buf()
    local file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":.")
    if vim.list_contains(request.files, file) and vim.bo[bufnr].buftype == "" then
        vim.bo[bufnr].modifiable = true
    end
end

--- @class llm.request
--- @field id integer
--- @field files string[] the files the llm will modify

--- start a request and lock the files (no modification allowed)
--- @param files string[]
--- @return integer
M.start = function(files)
    local req_id = math.floor(math.random() * UPPER_BOUND)
    requests[req_id] = {
        id = req_id,
        files = files,
    }

    local bufnr = vim.api.nvim_get_current_buf()
    local file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":.")
    if vim.list_contains(files, file) then
        vim.bo[bufnr].modifiable = false
    end

    return req_id
end

--- check if the file has an active llm request
--- @param file string should the result of the fnamemodify ":."
--- @return boolean
M.file_has_active_request = function(file)
    return vim.iter(requests):any(function(request)
        return vim.list_contains(request.files, file)
    end)
end

M.setup = function()
    vim.api.nvim_create_autocmd({ "BufEnter" }, {
        group = vim.api.nvim_create_augroup("llm.file.lock.sync", { clear = true }),
        callback = function(ev)
            local file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(ev.buf), ":.")
            local should_lock = M.file_has_active_request(file)
            if should_lock and vim.bo[ev.buf].buftype == "" then
                vim.bo[ev.buf].modifiable = false
            elseif vim.bo[ev.buf].buftype == "" and not vim.bo[ev.buf].modifiable then
                vim.bo[ev.buf].modifiable = true
            end
        end,
    })
end

return M
