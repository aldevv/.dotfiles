return {
  {
    "aldevv/ask-agent.nvim",
    dev = true,
    keys = {
      { "<leader>a", mode = "x", desc = "Ask agent about selection" },
      { "<leader>a", mode = "n", desc = "Ask agent about search match" },
      { "<leader>A", mode = { "n", "x" }, desc = "Send line/selection to claude tmux pane" },
      { "<leader>ah", mode = "n", desc = "Browse ask-agent Q&A history" },
    },
    cmd = { "Ask" },
    config = function()
      require("ask-agent").setup({})
    end,
  },
}
