vim.api.nvim_create_user_command("Symbols", "new | put=execute('digraphs')->split('\\n')[1:]", {})
