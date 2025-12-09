local M = {}

--- reads file and returns content, error
---
--- @param file_path string
--- @return string|nil,string|nil
--- @usage
--- local content, err = M.read_file("~/Documents/test.txt")
--- if content ~= nil then
---     vim.print(content)
--- else
---     vim.print(err)
--- end
---
M.read = function(file_path)
    file_path = vim.fn.expand(file_path)
    local file = io.open(file_path, "r")
    if not file then
        return nil, "error: could not open file: " .. file_path
    end

    local content = file:read("*all")
    file:close()
    return content, nil
end

---@param file_path string
---@param line string
---@return string|nil error message or nil if successful
M.append_line = function(file_path, line)
    file_path = vim.fn.expand(file_path)
    local file = io.open(file_path, "a")
    if not file then
        return "error: could not open file: " .. file_path
    end

    local _, err = file:write(line .. "\n")

    if err then
        file:close()
        return err
    end
    file:close()
end

--- @param path string
--- @param content string what we write to the file
--- @return string|nil error description of what went wrong
M.write = function(path, content)
    local file = io.open(path, "w")
    if file then
        file:write(content)
        file:close()
    else
        return "error: could not open file " .. path
    end
end

local MAX_PLANS_ON_DISK = 1000000

--- @param dir_path string formatted like ~/.claude/plans <-- notice no trailing forward slash
--- @return string|nil -- the absolute_path to the last modified file, or nil if an error occurred
M.last_modified_file_in_dir = function(dir_path)
    local expanded_dir_path = vim.fn.expand(dir_path)
    local dir = vim.uv.fs_opendir(expanded_dir_path, nil, MAX_PLANS_ON_DISK)
    if not dir then
        vim.notify("Failed to open directory: " .. expanded_dir_path, vim.log.levels.ERROR)
        return
    end

    local last_modified_file_path = nil
    local most_recent_modification_time = 0
    local entries = vim.uv.fs_readdir(dir)
    if type(entries) == "table" then
        for _, entry in ipairs(entries) do
            local absolute_path = expanded_dir_path .. "/" .. entry.name
            local stat = vim.uv.fs_stat(absolute_path)
            if stat and most_recent_modification_time < stat.mtime.sec then
                last_modified_file_path = absolute_path
                most_recent_modification_time = stat.mtime.sec
            end
        end
    end

    vim.uv.fs_closedir(dir)

    return last_modified_file_path
end

local icons = {
    lua = " ",
    py = "󰌠 ",
    tsx = " ",
    jsx = " ",
    json = " ",
    html = " ",
    css = " ",
    go = " ",
    rs = " ",
    ts = "󰛦 ",
    js = " ",
}

--- @param extension string
--- @return string
M.icon = function(extension)
    return icons[extension] or " "
end

return M
