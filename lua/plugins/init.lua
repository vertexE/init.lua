local M = {}

-- TODO: automate loading plugins
-- and enable "lazy" loading of any plugins
require("plugins.mini").config()
require("plugins.lsp").config()
require("plugins.snacks").config()
require("plugins.noice").config()

return M
