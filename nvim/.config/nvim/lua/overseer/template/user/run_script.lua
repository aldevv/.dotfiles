-- /home/kanon/.config/nvim/lua/overseer/template/user/run_script.lua
function get_ft_cmd()
  local file = vim.fn.expand("%:p")
  local ft_cmd = {
    [""]       = { file },
    go         = { "go", "run", file },
    python     = { "python", file },
    sh         = { "sh", file },
    rust       = { "cargo", "run" },
    javascript = { "bun", "run", file },
    typescript = { "bun", "run", file },
  }


  return ft_cmd
end

local ft_cmd = get_ft_cmd()
local filetypes = {} -- for condition at the bottom
for k, _ in pairs(ft_cmd) do
  table.insert(filetypes, k)
end

return {
  name = "run file",
  builder = function()
    return {
      cmd = ft_cmd[vim.bo.filetype] or {},
      components = {
        { "on_output_quickfix", set_diagnostics = true, open = true },
        "on_result_diagnostics",
        { "restart_on_save",    delay = 100 },
        "default",
      },
    }
  end,
  condition = {
    filetype = filetypes
  },
}
