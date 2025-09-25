local M = {}

M.lsp_signs = function()
    -- NOTE: err was 
    return { Error = "✘", Warn = "", Hint = "", Info = "󰭺" }
end

--- return a symbol representing the LSP server
--- @param name string
M.lsp_servers = function(name)
    if name:match("Copilot") then
        return " "
    end
    if name:match("lua") then
        return " "
    end
    if name:match("angular") then
        return " "
    end
    if name:match("ts_ls") then
        return " "
    end
    if name:match("rust_analyzer") then
        return "󱘗 "
    end
    if name:match("tailwindcss") then
        return " "
    end
    if name:match("gopls") then
        return " "
    end
    return ""
end

M.git = function()
    return {
        Branch = "",
    }
end

M.winbar = function()
    return {
        Folder = "󰉋",
        Separator = " ",
    }
end

return M
