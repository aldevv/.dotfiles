return {
  {
    "aldevv/ask-agent.nvim",
    dev = true,
    keys = {
      { "<leader>a", mode = "x", desc = "Ask agent about selection" },
      { "<leader>a", mode = "n", desc = "Ask agent about search match" },
    },
    cmd = { "Ask" },
    config = function()
      require("ask-agent").setup({})
    end,
  },
}
