return {
    {
        "cbochs/grapple.nvim",
        enabled = false,
        dependencies = {
            { "nvim-tree/nvim-web-devicons", lazy = true },
        },
        opts = {
            scope = "git", -- also try out "git_branch"
            icons = true, -- setting to "true" requires "nvim-web-devicons"
            status = false,
            win_opts = {
                width = 120,
                height = 12,
            },
        },
        keys = {
            { "<leader>fa", "<cmd>Grapple toggle<cr>", desc = "Tag a file" },
            { "<c-f>", "<cmd>Grapple toggle_tags<cr>", desc = "Toggle tags menu" },

            { "<c-a>", "<cmd>Grapple select index=1<cr>", desc = "Select first tag" },
            { "<c-r>", "<cmd>Grapple select index=2<cr>", desc = "Select second tag" },
            { "<c-s>", "<cmd>Grapple select index=3<cr>", desc = "Select third tag" },
            { "<c-t>", "<cmd>Grapple select index=4<cr>", desc = "Select fourth tag" },
            { "<c-g>", "<cmd>Grapple select index=5<cr>", desc = "Select fourth tag" },

            { "<c-s-n>", "<cmd>Grapple cycle_tags next<cr>", desc = "Go to next tag" },
            { "<c-s-p>", "<cmd>Grapple cycle_tags prev<cr>", desc = "Go to previous tag" },
        },
    },
}
