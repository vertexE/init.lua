local status = require("ui.status")

local clipboard = function()
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

--- @type PackSpec
local M = {
    config = function()
        local snacks = require("snacks")
        snacks.setup({
            statuscolumn = {},
            picker = {
                ui_select = true,
                win = {
                    input = {
                        keys = {
                            ["<c-g>"] = { "grep_selection", mode = { "i", "n" } },
                        },
                    },
                },
                actions = {
                    grep_selection = function(pick)
                        local picked = pick:selected({ fallback = false })
                        local items = #picked > 0 and picked or pick:items()
                        local glob = vim.iter(items)
                            :map(function(item)
                                return item.file
                            end)
                            :totable()
                        snacks.picker.grep({ glob = glob, layout = { preset = "sidebar" } })
                    end,
                },
            },
            input = {},
            image = {},
        })

        vim.api.nvim_create_autocmd("User", {
            pattern = "MiniFilesActionRename",
            callback = function(event)
                Snacks.rename.on_rename_file(event.data.from, event.data.to)
            end,
        })

        vim.keymap.set("n", "<leader>ff", function()
            snacks.picker.files({ layout = { preset = "vscode" } })
        end)

        vim.keymap.set("n", "<leader>fs", function()
            snacks.picker.lsp_workspace_symbols()
        end)

        vim.keymap.set("n", "<leader>gS", function()
            if status.is_open() then
                status.toggle_split()
            end
            snacks.picker.git_stash({ layout = { preset = "sidebar" } })
        end)

        vim.keymap.set("n", "<leader>fn", function()
            snacks.picker.icons()
        end, { desc = "snacks: find icon" })

        vim.keymap.set("n", "<leader>fN", function()
            snacks.picker.notifications()
        end, { desc = "snacks: notification history" })

        vim.keymap.set("n", "<leader>gi", function()
            if status.is_open() then
                status.toggle_split()
            end
            snacks.picker.git_log_file({ layout = { preset = "sidebar" } })
        end, { desc = "snacks: file history" })

        vim.keymap.set("n", "gD", function()
            if status.is_open() then
                status.toggle_split()
            end
            snacks.picker.lsp_declarations({ layout = { preset = "sidebar" } })
        end, { desc = "snacks: declarations" })

        vim.keymap.set("n", "gr", function()
            snacks.picker.lsp_references({
                layout = {
                    preset = "ivy",
                },
            })
        end, { desc = "snacks: references" })

        vim.keymap.set("n", "gi", function()
            snacks.picker.lsp_implementations({
                layout = {
                    preset = "ivy",
                },
            })
        end, { desc = "snacks: implementation" })

        vim.keymap.set("n", "<leader>gD", function()
            if status.is_open() then
                status.toggle_split()
            end
            snacks.picker.git_diff({ layout = { preset = "sidebar" } })
        end, { desc = "snacks: git diff" })

        vim.keymap.set("n", "gd", function()
            snacks.picker.lsp_definitions({
                layout = {
                    preset = "ivy",
                },
            })
        end, { desc = "snacks: lsp_definitions" })

        vim.keymap.set("n", "<leader>u", function()
            if status.is_open() then
                status.toggle_split()
            end
            snacks.picker.undo({ layout = { preset = "sidebar" } })
        end)

        vim.keymap.set("n", "<leader>fy", function()
            clipboard()
        end)
    end,
}

return M
