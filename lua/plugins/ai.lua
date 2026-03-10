local buf = require("buf")

--- @type PackSpec
local M = {
    requires = {
        "plenary.nvim",
        "CopilotChat.nvim",
    },
    config = function()
        require("sidekick").setup({
            nes = { enabled = false },
            cli = {
                win = {
                    layout = "float",
                    float = {
                        width = 0.8,
                        height = 0.85,
                    },
                },
            },
        })

        local state = {
            req_bufnr = -1,
            sel_start = -1,
            sel_end = -1,
        }

        vim.keymap.set({ "n", "x" }, "<leader>ac", function()
            state.req_bufnr = vim.api.nvim_get_current_buf()
            local sel_start, sel_end = buf.active_selection()
            state.sel_start = sel_start
            state.sel_end = sel_end
            require("sidekick.cli").toggle({ name = "claude", focus = true })
        end, { desc = "Sidekick Toggle Claude" })

        vim.keymap.set("t", "<c-cr>", function()
            require("assistant.terminal").msg_claude({
                req_bufnr = state.req_bufnr,
                sel_start = state.sel_start,
                sel_end = state.sel_end,
            })
        end)

        -- require("CopilotChat").setup({
        --     mappings = {
        --         accept_diff = {
        --             normal = "<C-CR>",
        --             insert = "<C-CR>",
        --         },
        --         reset = {
        --             normal = "<C-r>",
        --             insert = "<C-r>",
        --         },
        --     },
        -- })
    end,
}

return M
