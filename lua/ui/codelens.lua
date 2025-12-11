local M = {}

local ns = vim.api.nvim_create_namespace("user.codelens.references")

local draw_extmarks = function(bufnr, results)
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

    if bufnr ~= vim.api.nvim_get_current_buf() then
        return
    end

    for _, item in ipairs(results) do
        vim.api.nvim_buf_set_extmark(bufnr, ns, item.lnum - 1, 0, {
            virt_text = {
                { "", "CodeLensSeparator" },
                { "󰌹 ", "CodeLensContentIcon" },
                { item.count > 0 and tostring(item.count) or "no usage", "CodeLensContent" },
                { "", "CodeLensSeparator" },
            },
            virt_text_pos = "eol",
        })
    end
end

local refresh_codelens = function(bufnr)
    local clients = vim.lsp.get_clients({ bufnr = bufnr })
    local some_client_supports_codelens = false
    for _, client in ipairs(clients) do
        if
            client:supports_method("textDocument/documentSymbol") and client:supports_method("textDocument/references")
        then
            some_client_supports_codelens = true
        end
    end

    if not some_client_supports_codelens then
        return
    end

    vim.lsp.buf.document_symbol({
        on_list = function(symbols)
            local filtered = vim.iter(symbols.items)
                :filter(function(symbol)
                    return symbol.kind == "Function" or symbol.kind == "Method"
                end)
                :totable()

            if #filtered == 0 then
                vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
                return
            end

            local pending = #filtered
            local results = {}

            for i, symbol in ipairs(filtered) do
                local params = {
                    textDocument = vim.lsp.util.make_text_document_params(bufnr),
                    position = { line = symbol.lnum - 1, character = symbol.col - 1 },
                    context = { includeDeclaration = false },
                }

                vim.lsp.buf_request(bufnr, "textDocument/references", params, function(_, result, _, _)
                    results[i] = {
                        lnum = symbol.lnum,
                        count = result and #result or 0,
                    }

                    pending = pending - 1

                    if pending == 0 then
                        draw_extmarks(bufnr, results)
                    end
                end)
            end
        end,
    })
end

M.setup = function()
    vim.api.nvim_create_autocmd("BufEnter", {
        group = vim.api.nvim_create_augroup("user.codelens.attach", { clear = true }),
        callback = function(ev)
            vim.defer_fn(function()
                refresh_codelens(ev.buf)
            end, 3000)
        end,
    })

    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
        pattern = { "*.ts", "*.js", "*.tsx", "*.jsx", "*.go", "*.rs", "*.lua" },
        group = vim.api.nvim_create_augroup("user.codelens.refresh", { clear = true }),
        callback = function(ev)
            vim.api.nvim_buf_clear_namespace(ev.buf, ns, 0, -1)
            refresh_codelens(ev.buf)
        end,
    })
end

return M
