local M = {}

local request = require("assistant.request")

M.setup = function()
    request.setup()
end

return M
