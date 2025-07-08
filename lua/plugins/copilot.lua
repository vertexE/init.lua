return {
    {
        "josiahdenton/chat-context-ui.nvim",
        -- dir = "/Users/jfdenton/work/chat-context-ui.nvim",
        dependencies = {
            "CopilotC-Nvim/CopilotChat.nvim",
            "echasnovski/mini.nvim",
            -- other dependencies
        },
        keys = {
            {
                "<leader>ai",
                function()
                    require("chat-context-ui").open()
                end,
                mode = { "n" },
                desc = "open AI actions panel",
            },
        },
        --- @type ccc.PluginOpts
        opts = {
            ui = {
                layout = "split",
            },
            agent = {
                callback = function(prompt, resolve)
                    require("CopilotChat").ask(prompt, {
                        headless = true,
                        callback = function(response)
                            resolve(response)
                        end,
                    })
                end,
            },
        },
    },
    {
        "CopilotC-Nvim/CopilotChat.nvim",
        dependencies = {
            -- { "zbirenbaum/copilot.lua" }, -- or github/copilot.vim
            { "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
            {
                "github/copilot.vim",
                event = "InsertEnter",
                opts = {},
                config = function()
                    vim.g.copilot_on = false
                    vim.cmd("Copilot disable")

                    local toggle_copilot = function()
                        if vim.g.copilot_on then
                            vim.g.copilot_on = false
                            vim.cmd("Copilot disable")
                        else
                            vim.g.copilot_on = true
                            vim.cmd("Copilot enable")
                        end
                    end

                    vim.keymap.set("n", "<leader>ct", toggle_copilot, { desc = "Copilot: toggle" })

                    -- vim.keymap.set("n", "<leader>cp", "<cmd>Copilot panel<cr>", { desc = "Copilot: open panel" })
                    vim.keymap.set("i", "<C-J>", 'copilot#Accept("\\<CR>")', {
                        expr = true,
                        replace_keycodes = false,
                        desc = "Copilot: accept suggestion",
                    })
                    vim.keymap.set("i", "<C-e>", "<Plug>(copilot-dismiss)", { desc = "Copilot dismiss suggestion" })
                end,
            },
        },
        opts = {
            debug = false, -- Enable debugging
            -- See Configuration section for rest
            show_help = true,
            window = {
                layout = "float",
                width = 0.8,
                height = 0.5,
            },
            mappings = {
                accept_diff = {
                    normal = "<C-CR>",
                    insert = "<C-CR>",
                },
                reset = {
                    normal = "<C-r>",
                    insert = "<C-r>",
                },
            },
        },
        config = function(_, opts)
            local chat = require("CopilotChat")
            chat.setup(opts)

            vim.keymap.set({ "n", "v" }, "<leader>com", function()
                chat.open({
                    window = { layout = "float" },
                    auto_follow_cursor = true,
                })
            end, { desc = "copilot open menu" })
        end,
    },
}
