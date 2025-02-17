local M = {}

M.clipboard = function()
    local snacks = require("snacks")
    local hacked = require("hacked.clipboard")

    local custom_finder = function(opts)
        return vim.iter(hacked.list())
            :map(function(yank)
                local header = vim.split(yank.content, "\n")[1]
                return {
                    text = header,
                    value = yank.content,
                    preview = { text = yank.content, ft = yank.ft },
                }
            end)
            :totable()
    end

    local custom_picker_config = {
        layout = "telescope",
        finder = custom_finder,
        format = function(item)
            return { { item.text, "Title" } }
        end,
        preview = "preview", -- Use the default preview function
        actions = {},
        confirm = function(picker, item)
            picker:close()
            if item then
                vim.fn.setreg('"', item.value)
            end
        end,
    }

    snacks.picker.pick("custom_picker", custom_picker_config)
end

return M
