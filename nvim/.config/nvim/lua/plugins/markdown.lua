local script = vim.fn.stdpath("config") .. "/scripts/md-preview.py"

local function md_preview()
  return require("md-preview")
end

local function open_preview(theme)
  local filepath = vim.fn.expand("%:p")

  if theme ~= "light" then
    -- dark: Obsidian first, then Python preview
    if vim.fn.has("mac") == 1 and vim.loop.fs_stat("/Applications/Obsidian.app") then
      vim.fn.jobstart({ "open", "-a", "Obsidian", filepath }, { detach = true })
      return
    end
    if vim.fn.executable("obsidian") == 1 then
      vim.fn.jobstart({ "obsidian", filepath }, { detach = true })
      return
    end
  end

  vim.fn.jobstart({ "python3", script, filepath, theme or "dark" }, { detach = true })
end

return {
  {
    "aldevv/md-preview.nvim",
    dev = true,
    ft = { "markdown" },
    config = function()
      require("md-preview").setup()
    end,
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    ft = { "markdown" },
    opts = {},
    config = function(_, opts)
      require("render-markdown").setup(opts)
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function(ev)
          -- Static previews (Obsidian / Python script)
          vim.keymap.set("n", "<leader>mp", function() open_preview("dark") end,
            { buffer = ev.buf, desc = "Markdown preview (dark)" })
          vim.keymap.set("n", "<leader>mP", function() open_preview("light") end,
            { buffer = ev.buf, desc = "Markdown preview (light)" })
          -- Scroll-synced previews
          vim.keymap.set("n", "<leader>mv", function() md_preview().open("dark") end,
            { buffer = ev.buf, desc = "Markdown preview synced (dark)" })
          vim.keymap.set("n", "<leader>mV", function() md_preview().open("light") end,
            { buffer = ev.buf, desc = "Markdown preview synced (light)" })
          vim.keymap.set("n", "<leader>mq", function() md_preview().close() end,
            { buffer = ev.buf, desc = "Markdown preview synced (close)" })
        end,
      })
    end,
  },
  {
    "iamcco/markdown-preview.nvim",
    build = function()
      local plugin_path = require("lazy.core.config").options.root .. "/markdown-preview.nvim/app"
      vim.fn.system("cd " .. vim.fn.shellescape(plugin_path) .. " && npm install")
    end,
    ft = { "markdown" },
  },
  {
    "ekickx/clipboard-image.nvim",
    lazy = true,
    cmd = { "PasteImg" },
    config = function()
      local img_dir = vim.fn.expand("%:p:h") .. "/.files"
      require("clipboard-image").setup({
        default = {
          img_dir = img_dir,
          img_dir_txt = ".files",
          img_name = function() return os.date("%Y-%m-%d-%H-%M-%S") end,
        },
      })
    end,
    keys = {
      { "<leader>mi", "<cmd>PasteImg<cr>", desc = "Paste image from clipboard" },
    },
  },
}
