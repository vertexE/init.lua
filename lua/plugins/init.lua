local M = {}

-- TODO: automate loading plugins
-- and enable "lazy" loading of any plugins
require("plugins.mini").config()
require("plugins.lsp").config()
require("plugins.snacks").config()
require("plugins.noice").config()
require("plugins.dap").config()
require("plugins.kulala").config()
require("plugins.react").config()
require("plugins.vertexe").config()
require("plugins.ai").config()

return M
