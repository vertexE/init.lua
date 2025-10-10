return {
    config = function()
        local keymap = vim.keymap.set
        local dap = require("dap")
        local dapui = require("dapui")

        vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "MiniIconsRed", linehl = "", numhl = "" })
        vim.fn.sign_define(
            "DapBreakpointCondition",
            { text = "", texthl = "MiniIconsCyan", linehl = "", numhl = "" }
        )
        vim.fn.sign_define("DapStopped", { text = "", texthl = "MiniIconsOrange", linehl = "Visual", numhl = "" })
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

        require("dap-python").setup()
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
                    {
                        type = "pwa-node",
                        request = "launch",
                        runtimeArgs = {
                            "--inspect-brk",
                        },
                        name = "Debug Jest Test",
                        program = "${workspaceFolder}/node_modules/.bin/jest", -- Path to Jest executable
                        args = {
                            "--runInBand",
                            "--no-cache",
                            "${file}",
                        },
                        cwd = "${workspaceFolder}",
                        runtimeExecutable = "node",
                        console = "integratedTerminal",
                        internalConsoleOptions = "neverOpen",
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
            dap.terminate()
        end, { desc = "DAP: end session" })

        keymap("n", "<leader>d", function()
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

        keymap("n", "<leader>b", function()
            dap.toggle_breakpoint()
        end, { desc = "DAP: toggle breakpoint" })

        keymap("n", "<leader>B", function()
            dap.set_breakpoint()
        end, { desc = "DAP: set breakpoint" })

        keymap("n", "<leader>lp", function()
            dap.set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
        end, { desc = "DAP: set breakpoint with debug log" })

        keymap("n", "<leader>dr", function()
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
        end, { desc = "DAP: preview value" })

        keymap("n", "<Leader>ds", function()
            local widgets = require("dap.ui.widgets")
            widgets.centered_float(widgets.scopes)
        end, { desc = "DAP: show scopes" })

        -- vim.keymap.set("n", "<leader>do", dapui.open, { desc = "DAP: open ui" })
        -- vim.keymap.set("n", "<leader>dc", dapui.close, { desc = "DAP: close ui" })
        vim.keymap.set("n", "<leader>dm", dapui.toggle, { desc = "DAP: toggle ui" })
    end,
}
