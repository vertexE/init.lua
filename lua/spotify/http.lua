local M = {}

function M.request(method, url, opts)
    local async = vim.async
    -- verbose keeps JSON error bodies with this vim.net implementation. Its stderr
    -- includes Authorization headers: never log or return raw transport errors.
    opts.verbose, opts.retry = true, 0
    local err, response = async.timeout(15000, async.run(function()
        return async.await(4, vim.net.request, method, url, opts)
    end))
    if err then
        error("Spotify: network request failed", 0)
    end
    if response.body == "" then
        return nil
    end
    local ok, data = pcall(vim.json.decode, response.body)
    if not ok or type(data) ~= "table" then
        error("Spotify: invalid API response", 0)
    end
    return data
end

return M
