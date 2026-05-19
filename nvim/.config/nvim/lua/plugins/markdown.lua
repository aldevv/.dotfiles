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
      require("md-preview").setup()
    end,
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    -- enabled = false,
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
}
