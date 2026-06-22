local script = vim.fn.stdpath("config") .. "/scripts/md-preview.py"

local function md_preview()
  return require("md-preview")
end

return {
  {
    "aldevv/md-preview.nvim",
    dev = true,
    ft = { "markdown" },
    config = function()
      require("md-preview").setup({ prefer_global_mdp = true })
    end,
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    -- Load before the buffer renders so the first paint already has marks.
    -- ft= waits for FileType (which fires AFTER BufReadPost), so the file
    -- shows raw markdown for a beat before the plugin attaches.
    event = { "BufReadPre *.md", "BufNewFile *.md", "BufReadPre *.markdown", "BufNewFile *.markdown" },
    opts = {
      render_modes = { "n", "c" },
      debounce = 200,
      -- After the plugin attaches for the first time, restart treesitter highlights
      -- so colors aren't stale.
      restart_highlighter = true,
    },
    config = function(_, opts)
      require("render-markdown").setup(opts)
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function(ev)
          -- Skip TOC sidebar buffers (filetype=markdown but a generated scratch).
          if vim.b[ev.buf].is_mdtoc then return end
          -- Scroll-synced previews
          vim.keymap.set("n", "<leader>mv", function() md_preview().open("dark") end,
            { buffer = ev.buf, desc = "Markdown preview synced (dark)" })
          vim.keymap.set("n", "<leader>mV", function() md_preview().open("light") end,
            { buffer = ev.buf, desc = "Markdown preview synced (light)" })
          vim.keymap.set("n", "<leader>mq", function() md_preview().close() end,
            { buffer = ev.buf, desc = "Markdown preview synced (close)" })
          vim.keymap.set("n", "M", function()
            local path = vim.api.nvim_buf_get_name(ev.buf)
            if path == "" then
              vim.notify("mdp: buffer has no file", vim.log.levels.WARN)
              return
            end
            if vim.fn.executable("mdp") == 0 then
              vim.notify("mdp: not on PATH", vim.log.levels.ERROR)
              return
            end
            vim.fn.jobstart({ "mdp", path }, { detach = true })
          end, { buffer = ev.buf, desc = "mdp (no server)" })
        end,
      })
    end,
  },
  -- TOC sidebar (right column) for markdown buffers, styled by render-markdown.
  -- Defaults: go = toggle, ]h / [h = next/prev parent heading.
  {
    "aldevv/markdown-toc.nvim",
    dev = true,
    dependencies = { "MeanderingProgrammer/render-markdown.nvim" },
    ft = { "markdown" },
    opts = {},
  },
}
