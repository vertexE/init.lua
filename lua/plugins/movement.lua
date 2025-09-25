return {
    {
        "vertexE/fold.nvim",
        dependencies = {
            "mini.nvim",
        },
        keys = {
            {
                "<leader>fi",
                function()
                    if require("fold").focused() then
                        require("fold").text({})
                        return
                    end

                    vim.ui.input({
                        prompt = "Focus on buffer text",
                    }, function(input)
                        require("fold").text({ input })
                    end)
                end,
                mode = { "n" },
                desc = "focus on text in buffer",
            },
            {
                "<leader>E",
                function()
                    require("fold").diagnostics()
                end,
                mode = { "n" },
                desc = "focus on diagnostics",
            },
            {
                "<leader>M",
                function()
                    require("fold").marks()
                end,
                mode = { "n" },
                desc = "focus on marks",
            },
            {
                "<leader>zz",
                function()
                    require("fold").zen()
                end,
                mode = { "n", "x" },
                desc = "focus on visual selection",
            },
            {
                "<leader>D",
                function()
                    require("fold").diff()
                end,
                mode = { "n" },
                desc = "focus on changes",
            },
        },
    },
    {
        "jake-stewart/multicursor.nvim",
        enabled = false,
        branch = "1.0",
        event = "VeryLazy",
        config = function()
            local mc = require("multicursor-nvim")
            mc.setup()

            -- Add or skip cursor above/below the main cursor.
            vim.keymap.set({ "n", "x" }, "<up>", function()
                mc.lineAddCursor(-1)
            end)
            vim.keymap.set({ "n", "x" }, "<down>", function()
                mc.lineAddCursor(1)
            end)
            vim.keymap.set({ "n", "x" }, "<leader><up>", function()
                mc.lineSkipCursor(-1)
            end)
            vim.keymap.set({ "n", "x" }, "<leader><down>", function()
                mc.lineSkipCursor(1)
            end)

            -- Add or skip adding a new cursor by matching word/selection
            vim.keymap.set({ "n", "x" }, "<leader>n", function()
                mc.matchAddCursor(1)
            end)
            vim.keymap.set({ "n", "x" }, "<leader>s", function()
                mc.matchSkipCursor(1)
            end)
            -- vim.keymap.set({ "n", "x" }, "<leader>N", function()
            --     mc.matchAddCursor(-1)
            -- end)
            vim.keymap.set({ "n", "x" }, "<leader>S", function()
                mc.matchSkipCursor(-1)
            end)

            -- Add and remove cursors with control + left click.
            vim.keymap.set("n", "<c-leftmouse>", mc.handleMouse)
            vim.keymap.set("n", "<c-leftdrag>", mc.handleMouseDrag)
            vim.keymap.set("n", "<c-leftrelease>", mc.handleMouseRelease)

            -- Disable and enable cursors.
            vim.keymap.set({ "n", "x" }, "<c-q>", mc.toggleCursor)

            -- Mappings defined in a keymap layer only apply when there are
            -- multiple cursors. This lets you have overlapping mappings.
            mc.addKeymapLayer(function(layerSet)
                -- Select a different cursor as the main one.
                layerSet({ "n", "x" }, "<left>", mc.prevCursor)
                layerSet({ "n", "x" }, "<right>", mc.nextCursor)

                -- Delete the main cursor.
                layerSet({ "n", "x" }, "<leader>x", mc.deleteCursor)

                -- Enable and clear cursors using escape.
                layerSet("n", "<esc>", function()
                    if not mc.cursorsEnabled() then
                        mc.enableCursors()
                    else
                        mc.clearCursors()
                    end
                end)
            end)

            -- Customize how cursors look.
            local hl = vim.api.nvim_set_hl
            hl(0, "MultiCursorCursor", { reverse = true })
            hl(0, "MultiCursorVisual", { link = "Visual" })
            hl(0, "MultiCursorSign", { link = "SignColumn" })
            hl(0, "MultiCursorMatchPreview", { link = "Search" })
            hl(0, "MultiCursorDisabledCursor", { reverse = true })
            hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
            hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })
        end,
    },
}
