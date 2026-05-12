local stream = require("editor.stream")

vim.api.nvim_create_user_command("Symbols", "new | put=execute('digraphs')->split('\\n')[1:]", {})

vim.api.nvim_create_user_command("Implement", function(opts)
    local winr = vim.api.nvim_get_current_win()
    stream.start_change_stream(winr, opts.args)
end, { nargs = "?" })

--- create user command for stream stop
vim.api.nvim_create_user_command("ImplementHalt", function()
    stream.stop_change_stream()
end, {})
