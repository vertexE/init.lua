local M = {}

local group = vim.api.nvim_create_augroup("user.lazy.load", { clear = true })

--- @param requires string[]
local load_dependencies = function(requires)
    for _, plugin in ipairs(requires) do
        vim.cmd.packadd(plugin)
    end
end

--- @param plugin { path: string, spec: vim.pack.Spec }
--- @param data PackSpec
local load_plugin = function(plugin, data)
    if data.requires then
        load_dependencies(data.requires)
    end
    vim.cmd.packadd(plugin.spec.name)
    if data.config then
        data.config(plugin)
    end
end

--- @class PackSpec
--- @field dependency ?boolean
--- @field config ?fun(plugin?: { path: string, spec: vim.pack.Spec })
--- @field requires ?string[] list of dependencies that must be loaded before this plugin loads
--- @field event ?string
--- @field pattern ?(string|string[]) can define with event
--- @field cmd ?string
--- @field keys ?({mode:string, lhs:string} | {[1]: string, mode:string} | {[1]: string})[]

--- @param plugins (string|vim.pack.Spec)[]
M.lazy_load = function(plugins)
    vim.pack.add(plugins, {
        load = function(plugin)
            --- @type PackSpec
            local data = plugin.spec.data

            -- default behavior
            if not plugin.spec.data then
                vim.cmd.packadd(plugin.spec.name)
                return
            end

            if data.dependency then
                return
            end

            -- only a .config set
            local has_no_trigger = not data.keys and not data.event and not data.cmd
            if has_no_trigger then
                load_plugin(plugin, data)
                return
            end

            if data.event then
                vim.api.nvim_create_autocmd(data.event, {
                    group = group,
                    once = true,
                    pattern = data.pattern or "*",
                    callback = vim.schedule_wrap(function()
                        load_plugin(plugin, data)
                    end),
                })
            end

            if data.cmd then
                vim.api.nvim_create_user_command(data.cmd, function(cmd_args)
                    vim.api.nvim_del_user_command(data.cmd)
                    load_plugin(plugin, data)
                    -- execute the command after loading
                    vim.api.nvim_cmd({
                        cmd = data.cmd,
                        args = cmd_args.fargs,
                        bang = cmd_args.bang,
                        nargs = cmd_args.nargs,
                        range = cmd_args.range ~= 0 and { cmd_args.line1, cmd_args.line2 } or nil,
                        count = cmd_args.count ~= -1 and cmd_args.count or nil, -- INFO: why not 0?
                    }, {})
                end, { nargs = "*", range = true, bang = true, complete = "file" })
            end

            if data.keys then
                for _, key in ipairs(data.keys) do
                    local mode = key.mode or "n"
                    local lhs = key.lhs or key[1]
                    vim.keymap.set(mode, lhs, function()
                        vim.keymap.del(mode, lhs)
                        load_plugin(plugin, data)
                        -- Re-execute the keypress after loading
                        local escaped_lhs = vim.api.nvim_replace_termcodes(lhs, true, false, true)
                        vim.api.nvim_feedkeys(escaped_lhs, "m", false)
                    end, { desc = "load " .. plugin.spec.name })
                end
            end
        end,
    })
end

return M
