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
