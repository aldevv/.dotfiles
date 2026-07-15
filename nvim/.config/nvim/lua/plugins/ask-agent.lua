return {
  {
    "aldevv/ask-agent.nvim",
    dev = true,
    keys = {
      { "<leader>A", mode = { "n", "x" }, desc = "Edit line/selection in place via agent" },
      { "<leader>ao", mode = { "n", "x" }, desc = "Ask agent (answer in float)" },
      { "<leader>ac", mode = { "n", "x" }, desc = "Send line/selection to claude tmux pane" },
      { "<leader>ah", mode = "n", desc = "Browse ask-agent Q&A history" },
    },
    cmd = { "Ask" },
    config = function()
      require("ask-agent").setup({})
    end,
  },
}
