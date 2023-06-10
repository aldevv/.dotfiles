--
-- these are loaded so you can do : lua put({1,2,3})
function _G._replace_termcodes(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

function _G._is_work_env()
  return vim.fn.system("cd ~/.dotfiles; git branch --show-current | tr -d '\\n'; cd -") == "work"
end

-- must be used after the plugins are loaded
function _G._is_plugin_loaded(plugin)
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
  if type(plugin) ~= "table" then
    plugin_name = vim.split(vim.split(plugin, "/")[2], ".", true)[1]
    return plugin_name, enabled
  end

  plugin_name = vim.split(vim.split(plugin[1], "/")[2], ".", true)[1]
  if vim.tbl_contains(plugin, "enabled") then
    enabled = plugin["enabled"]
  end
  return plugin_name, enabled
end

function _G._is_plugin_enabled(plugin)
  for _, plugin_entry in pairs(require("plugins")) do
    local plugin_name, enabled = get_plugin(plugin_entry)
    if plugin_name == plugin and enabled then
      return true
    end
  end
  return false
end
