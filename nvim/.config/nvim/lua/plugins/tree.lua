-- nvim-tree: file explorer
--
-- Conventions:
--   <Tab>   toggle tree
--   sE      reveal current buffer in the tree
--
-- Inside the tree buffer, default mappings stay (a/c/d/r/x/y/-/...) plus:
--   colemak motion:
--     n         move down (was j)
--     e         move up   (was k)
--     i         open / edit node (was l)
--     h         close node (default; physical key unchanged on colemak)
--   netrw-style:
--     %         create file (or dir with trailing /)
--     R         rename
--     o         open in horizontal split
--     v         open in vertical split
--     t         open in tab
--     -         parent dir (already default)
--     <C-r>     refresh (was R)
--   preview:
--     M            one-shot `mdp <file>`. No synced server, no editor swap;
--                  tree stays focused.
--     <leader>mv   synced preview via md-preview.nvim (dark). Opens the file
--                  in the editor so the live-sync autocmds attach.
--     <leader>mV   synced preview (light).
--     <leader>mq   close synced preview.
--
-- The preview keys mirror the bindings already set on markdown buffers in
-- lua/plugins/markdown.lua. From the tree they:
--   * open the file in the editor (so md-preview.nvim's autocmds see it),
--   * then call require("md-preview").open(theme) for .md / .markdown,
--   * or fall back to `mdp <path>` via jobstart for any other file mdp can
--     render (pandoc-writable docs like .rst / .org / .tex / ...).
--
-- Notes:
--   - netrw is disabled in init.lua (vim.g.loaded_netrw / loaded_netrwPlugin = 1)
--     to kill the gray flash on `nvim <dir>` startup. The s-prefix bindings in
--     lua/keybindings/init.lua are rewired to :NvimTree* equivalents.
--   - `nvim-tree/nvim-web-devicons` is already declared as a dep elsewhere;
--     lazy.nvim dedupes.

return {
  "nvim-tree/nvim-tree.lua",
  version = "*",
  lazy = false,
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    {
      "<Tab>",
      function() require("nvim-tree.api").tree.toggle() end,
      desc = "tree: toggle",
    },
    {
      "sE",
      function()
        require("nvim-tree.api").tree.find_file({ open = true, focus = true, update_root = false })
      end,
      desc = "tree: reveal current file",
    },
  },
  config = function()
    -- vim.g.loaded_netrw = 1
    -- vim.g.loaded_netrwPlugin = 1
    vim.opt.termguicolors = true

    local function preview_node(node, theme)
      if not node then return end
      if node.type ~= "file" then
        vim.notify("preview: select a file", vim.log.levels.WARN)
        return
      end
      local path = node.absolute_path
      local ext = path:match("%.([^.]+)$") or ""
      ext = ext:lower()
      if ext == "md" or ext == "markdown" then
        -- open the file so md-preview.nvim's autocmds bind to the right buffer,
        -- then call the same entry point the markdown-buffer keys use.
        vim.cmd("edit " .. vim.fn.fnameescape(path))
        require("md-preview").open(theme)
        return
      end
      -- non-markdown: fall back to the mdp CLI directly so pandoc-writable
      -- docs (rst, org, tex, ...) still render. no live sync in this path.
      if vim.fn.executable("mdp") == 0 then
        vim.notify("mdp: not on PATH", vim.log.levels.ERROR)
        return
      end
      vim.fn.jobstart({ "mdp", "--theme", theme, path }, { detach = true })
    end

    local function close_preview()
      local ok, md = pcall(require, "md-preview")
      if ok then md.close() end
    end

    local function on_attach(bufnr)
      local api = require("nvim-tree.api")
      api.config.mappings.default_on_attach(bufnr)
      local function opts(desc)
        return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
      end

      -- colemak motion (n=down, e=up, i=open). h keeps the default close_node
      -- since its physical position is unchanged on colemak.
      vim.keymap.set("n", "n", "j", opts("down"))
      vim.keymap.set("n", "e", "k", opts("up"))
      vim.keymap.set("n", "i", api.node.open.edit, opts("open / edit"))

      -- default_on_attach binds K to First Sibling; drop it so global K -> N wins.
      pcall(vim.keymap.del, "n", "K", { buffer = bufnr })

      -- netrw-style bindings (similar to `:Ex`).
      -- `-` (parent dir) is already the nvim-tree default.
      vim.keymap.set("n", "%", api.fs.create, opts("create (trailing / = dir)"))
      vim.keymap.set("n", "R", api.fs.rename, opts("rename"))
      vim.keymap.set("n", "o", api.node.open.horizontal, opts("open horizontal split"))
      vim.keymap.set("n", "v", api.node.open.vertical, opts("open vertical split"))
      vim.keymap.set("n", "t", api.node.open.tab, opts("open in tab"))
      -- Default `R` was refresh; remap that to <C-r>.
      vim.keymap.set("n", "<C-r>", api.tree.reload, opts("refresh"))

      -- `M` is a one-shot `mdp <file>`: no synced server, doesn't touch the
      -- editor buffer, tree stays focused.
      vim.keymap.set("n", "M", function()
        local node = api.tree.get_node_under_cursor()
        if not node or node.type ~= "file" then
          vim.notify("mdp: select a file", vim.log.levels.WARN)
          return
        end
        if vim.fn.executable("mdp") == 0 then
          vim.notify("mdp: not on PATH", vim.log.levels.ERROR)
          return
        end
        vim.fn.jobstart({ "mdp", node.absolute_path }, { detach = true })
      end, opts("mdp (no server)"))

      -- markdown preview keys mirror the bindings on markdown buffers
      -- (lua/plugins/markdown.lua); see header comment above.
      vim.keymap.set("n", "<leader>mv", function()
        preview_node(api.tree.get_node_under_cursor(), "dark")
      end, opts("md preview (dark)"))
      vim.keymap.set("n", "<leader>mV", function()
        preview_node(api.tree.get_node_under_cursor(), "light")
      end, opts("md preview (light)"))
      vim.keymap.set("n", "<leader>mq", close_preview, opts("md preview close"))
    end

    require("nvim-tree").setup({
      on_attach = on_attach,
      hijack_cursor = true,
      sync_root_with_cwd = true,
      view = {
        width = 35,
        side = "left",
      },
      renderer = {
        group_empty = true,
        highlight_git = "name",
        icons = {
          show = { file = true, folder = true, folder_arrow = true, git = true },
        },
      },
      git = {
        enable = true,
        timeout = 400,
      },
      diagnostics = {
        enable = true,
        severity = { min = vim.diagnostic.severity.HINT },
      },
      filters = {
        dotfiles = false,
        custom = { ".git$" },
      },
      actions = {
        open_file = { quit_on_open = true, resize_window = true },
      },
    })
  end,
}
