local harpoon = require("harpoon");
local extensions = require("harpoon.extensions");

local one_list_per_project = true
local cfg = {
  settings = {
    save_on_toggle = true,
    sync_on_ui_close = false,
    key = function()
      local is_git_repo = vim.fn.system("git rev-parse --is-inside-work-tree 2> /dev/null") == "true\n"
      if is_git_repo then
        if one_list_per_project then
          return vim.fn.system("git config --get remote.origin.url")
        else
          -- one list per branch
          return vim.fn.system("git rev-parse --abbrev-ref HEAD")
        end
      end
      return vim.loop.cwd()
    end,
  }
}
local ok, work = pcall(require, "work")
if ok then
  local projects = {}
  projects = work.harpoon_projects
  cfg = vim.tbl_extend("keep", cfg, projects)
end

harpoon:setup(cfg)

-- runs a vim command
-- harpoon:extend(extensions.builtins.command_on_nav('echo "hi"'));

-- extension to add keybindings for the harpoon menu
harpoon:extend({
  UI_CREATE = function(cx)
    vim.keymap.set("n", "<C-v>", function()
      harpoon.ui:select_menu_item({ vsplit = true })
    end, { buffer = cx.bufnr })

    vim.keymap.set("n", "<C-x>", function()
      harpoon.ui:select_menu_item({ split = true })
    end, { buffer = cx.bufnr })

    vim.keymap.set("n", "<C-t>", function()
      harpoon.ui:select_menu_item({ tabedit = true })
    end, { buffer = cx.bufnr })
  end,
  -- same as command_on_nav
  -- NAVIGATE = function()
  --     vim.cmd(cmd)
  -- end,
})

-- local ok, telescope = pcall(require, "telescope")
-- if not ok then
--   return
-- end
-- telescope.load_extension("harpoon")
