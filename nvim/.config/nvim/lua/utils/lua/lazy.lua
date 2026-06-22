local M = {}
-- must be used after the plugins are loaded
function M.is_plugin_loaded(plugin)
    for _, value in pairs(require("lazy").plugins()) do
        if value[1] ~= nil then
            if value[1]:find(plugin) ~= nil then
                return true
            end
        end
    end
    return false
end

local get_plugin = function(plugin)
    local enabled = true
    local plugin_name
    if type(plugin) ~= "table" then
        plugin_name = vim.split(vim.split(plugin, "/")[2], ".", true)[1]
        return plugin_name, enabled
    end

    plugin_name = vim.split(vim.split(plugin[1], "/")[2], ".", true)[1]
    -- check the KEY, not the values. vim.tbl_contains scans values; we want
    -- "does this table have an `enabled` key?", which is `plugin.enabled ~= nil`.
    if plugin.enabled ~= nil then
        enabled = plugin.enabled
    end
    return plugin_name, enabled
end

function M.is_plugin_enabled(plugin)
    local plugins = require("plugins")
    if os.getenv("DEBUG_NVIM") then
        plugins = require("plugins-debug")
    end
    for _, plugin_entry in pairs(plugins) do
        local plugin_name, enabled = get_plugin(plugin_entry)
        if plugin_name == plugin and enabled then
            return true
        end
    end
    return false
end

return M
