return {
    {
        "nvim-neotest/neotest",
        event = "VeryLazy",
        dependencies = {
            "nvim-neotest/nvim-nio",
            "nvim-lua/plenary.nvim",
            "antoinemadec/FixCursorHold.nvim",
            "nvim-treesitter/nvim-treesitter",
            -- testing adapters
            -- {
            --     "nvim-neotest/neotest-python",
            --     commit = "2e83d2bc00acbcc1fd529dbf0a0e677cabfe6b50",
            -- },
            "nvim-neotest/neotest-go",
            "nvim-neotest/neotest-jest",
        },
        config = function()
            require("neotest").setup({
                adapters = {
                    -- require("neotest-python")({
                    --     dap = { justMyCode = false },
                    -- }),
                    require("neotest-jest")({
                        jestCommand = function(path)
                            return string.format("npx jest -- %s", path)
                        end,
                        jestConfigFile = "custom.jest.config.ts",
                        env = { CI = true },
                        cwd = function(path)
                            return vim.fn.getcwd()
                        end,
                    }),
                    require("rustaceanvim.neotest"),
                    require("neotest-go"),
                },
            })
            -- generalized test debugging keymaps
            vim.keymap.set("n", "<leader>nt", function()
                require("neotest").run.run()
            end, { desc = "Neotest: run test" })

            vim.keymap.set("n", "<leader>nf", function()
                require("neotest").run.run(vim.fn.expand("%"))
            end, { desc = "Neotest: run file" })

            vim.keymap.set("n", "<leader>dt", function()
                require("neotest").run.run({ strategy = "dap" })
            end, { desc = "Neotest: debug test" })

            vim.keymap.set("n", "<leader>df", function()
                require("neotest").run.run({ vim.fn.expand("%"), strategy = "dap" })
            end, { desc = "Neotest: debug file" })

            vim.keymap.set("n", "<leader>ne", function()
                require("neotest").output.open({ enter = true, auto_close = true })
            end, { desc = "Neotest: show test outcome" })

            vim.keymap.set("n", "<leader>no", function()
                require("neotest").summary.toggle()
            end, { desc = "Neotest: show test summary panel" })

            vim.keymap.set("n", "<leader>[n", function()
                require("neotest").jump.prev({ status = "failed" })
            end)

            vim.keymap.set("n", "<leader>]n", function()
                require("neotest").jump.next({ status = "failed" })
            end)
        end,
    },
    {
        "rcarriga/nvim-dap-ui",
        event = "VeryLazy",
        dependencies = {
            "mfussenegger/nvim-dap",
            "theHamsta/nvim-dap-virtual-text",
            "nvim-neotest/nvim-nio",
            -- adapters
            "mfussenegger/nvim-dap-python",
            "leoluz/nvim-dap-go",
            "jbyuki/one-small-step-for-vimkind",
        },
        config = function()
            local keymap = vim.keymap.set
            local dap = require("dap")
            local dapui = require("dapui")

            vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "MiniIconsRed", linehl = "", numhl = "" })
            vim.fn.sign_define(
                "DapBreakpointCondition",
                { text = "", texthl = "MiniIconsCyan", linehl = "", numhl = "" }
            )
            vim.fn.sign_define("DapStopped", { text = "", texthl = "MiniIconsGreen", linehl = "Visual", numhl = "" })
            vim.fn.sign_define(
                "DapBreakpointRejected",
                { text = "", texthl = "MiniIconsPurple", linehl = "", numhl = "" }
            )

            dapui.setup({
                floating = {
                    max_height = nil, -- These can be integers or a float between 0 and 1.
                    max_width = nil, -- Floats will be treated as percentage of your screen.
                    border = "rounded", -- Border style. Can be "single", "double" or "rounded"
                    mappings = {
                        close = { "q", "<Esc>" },
                    },
                },
                render = {
                    indent = 2,
                },
                layouts = {
                    {
                        elements = {
                            { id = "breakpoints", size = 0.3 },
                            { id = "scopes", size = 0.3 },
                            { id = "watches", size = 0.3 },
                        },
                        size = 40,
                        position = "left",
                    },
                    {
                        elements = {
                            { id = "repl", size = 0.5 },
                            { id = "console", size = 0.5 },
                        },
                        position = "bottom",
                        size = 15,
                    },
                },
                controls = {
                    -- Requires Neovim nightly (or 0.8 when released)
                    enabled = true,
                    -- Display controls in this element
                    element = "repl",
                    icons = {
                        pause = "",
                        play = "",
                        step_into = "󰘕",
                        step_over = "󱞫",
                        step_out = "󰘖",
                        step_back = "",
                        run_last = "↻ ",
                        terminate = "□ ",
                    },
                },
            })
            local dapvt = require("nvim-dap-virtual-text")
            dapvt.setup({
                display_callback = function(variable, buf, stackframe, node, options)
                    if #variable.value > 10 then
                        return " <...> "
                    end

                    if options.virt_text_pos == "inline" then
                        return " = " .. variable.value
                    else
                        return variable.name .. " = " .. variable.value
                    end
                end,
            })
            require("dap-python").setup()
            require("dap-go").setup()

            local js_debug_path = vim.fn.expand("$MASON/packages/js-debug-adapter/js-debug/src/dapDebugServer.js")

            dap.adapters["pwa-node"] = {
                type = "server",
                host = "localhost",
                port = "${port}",
                executable = {
                    command = "node",
                    -- https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation#vscode-js-debug
                    args = { js_debug_path, "${port}" },
                },
            }

            dap.adapters["pwa-chrome"] = {
                type = "server",
                host = "localhost",
                port = "${port}",
                executable = {
                    command = "node",
                    -- https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation#vscode-js-debug
                    args = { js_debug_path, "${port}" },
                },
            }

            -- support for node projects
            local js_filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact" }
            for _, language in ipairs(js_filetypes) do
                if not dap.configurations[language] then
                    dap.configurations[language] = {
                        {
                            type = "pwa-chrome",
                            name = "Attach - Remote Debugging",
                            request = "attach",
                            program = "${file}",
                            cwd = vim.fn.getcwd(),
                            sourceMaps = true,
                            protocol = "inspector",
                            port = 9222, -- Start Chrome google-chrome --remote-debugging-port=9222
                            webRoot = "${workspaceFolder}",
                        },
                        {
                            type = "pwa-chrome",
                            name = "Launch Chrome",
                            request = "launch",
                            url = "http://localhost:4200",
                            webRoot = "${workspaceFolder}",
                            userDataDir = "${workspaceFolder}/.vscode/vscode-chrome-debug-userdatadir",
                        },
                        {
                            type = "pwa-node",
                            request = "launch",
                            name = "Launch file",
                            program = "${file}",
                            cwd = "${workspaceFolder}",
                        },
                        {
                            type = "pwa-node",
                            request = "attach",
                            name = "Attach",
                            processId = require("dap.utils").pick_process,
                            cwd = "${workspaceFolder}",
                        },
                        {
                            type = "pwa-node",
                            request = "attach",
                            name = "Auto Attach", -- run the node proces with --inspect
                            cwd = "${workspaceFolder}",
                        },
                    }
                end
            end

            -- support for nvim/lua
            dap.configurations.lua = {
                {
                    type = "nlua",
                    request = "attach",
                    name = "Attach to running Neovim instance",
                },
            }

            dap.adapters.nlua = function(callback, config)
                callback({ type = "server", host = config.host or "127.0.0.1", port = config.port or 8086 })
            end

            vim.keymap.set("n", "<leader>dl", function()
                require("osv").launch({ port = 8086 })
            end, { noremap = true })

            keymap("n", "<leader>q", function()
                dapvt.disable()
                dap.terminate()
            end, { desc = "DAP: end session" })

            keymap("n", "<leader>n", function()
                dapvt.enable()
                dap.continue()
            end, { desc = "DAP: continue" })

            keymap("n", "<leader>j", function()
                dap.step_over()
            end, { desc = "DAP: step over" })

            keymap("n", "<leader>i", function()
                dap.step_into()
            end, { desc = "DAP: step into" })

            keymap("n", "<leader>r", function()
                dap.restart()
            end, { desc = "DAP: restart" })

            keymap("n", "<leader>rc", function()
                dap.run_to_cursor()
            end, { desc = "DAP: run to cursor" })

            -- keymap("n", "<leader>o", function()
            --     dap.step_out()
            -- end, { desc = "DAP: step out" })

            keymap("n", "<Leader>b", function()
                dap.toggle_breakpoint()
            end, { desc = "DAP: toggle breakpoint" })

            keymap("n", "<Leader>B", function()
                dap.set_breakpoint()
            end, { desc = "DAP: set breakpoint" })

            keymap("n", "<leader>lp", function()
                dap.set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
            end, { desc = "DAP: set breakpoint with debug log" })

            -- keymap("n", "<Leader>dl", function()
            --     require("dap").run_last()
            -- end, { desc = "DAP: re-run last" })

            keymap("n", "<Leader>dr", function()
                require("dap").repl.open()
            end, { desc = "DAP: open repl" })

            keymap({ "n", "v" }, "<leader>K", function()
                require("dapui").eval(nil, { enter = true })
            end, { desc = "DAP: eval variable" })

            keymap("n", "<leader>de", function()
                vim.ui.input({ prompt = "evaluate expression" }, function(s)
                    require("dapui").eval(s, { enter = true })
                end)
            end, { desc = "DAP: close ui" })

            keymap({ "n", "v" }, "<leader>dp", function()
                require("dap.ui.widgets").preview()
            end, { desc = "DAP: preview value(???)" })

            keymap("n", "<Leader>ds", function()
                local widgets = require("dap.ui.widgets")
                widgets.centered_float(widgets.scopes)
            end, { desc = "DAP: show scopes" })

            -- vim.keymap.set("n", "<leader>do", dapui.open, { desc = "DAP: open ui" })
            -- vim.keymap.set("n", "<leader>dc", dapui.close, { desc = "DAP: close ui" })
            vim.keymap.set("n", "<leader>dm", dapui.toggle, { desc = "DAP: toggle ui" })
        end,
    },
}
