local function req(module)
  return function(name, opts)
    require(module)
  end
end

return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      { "rcarriga/nvim-dap-ui",             module = "dapui" },
      { "theHamsta/nvim-dap-virtual-text",  module = "nvim-dap-virtual-text" },
      { "nvim-telescope/telescope-dap.nvim" },
      { "rcarriga/cmp-dap" },
      { "mfussenegger/nvim-dap-python" },
      { "mxsdev/nvim-dap-vscode-js" },
      { "leoluz/nvim-dap-go" },
      "williamboman/mason.nvim",
    },
    -- module = "dap",
    config = req("lsp.dap.dap"),
    module = "dap",
  },
  "jayp0521/mason-nvim-dap.nvim",
  {
    "jbyuki/one-small-step-for-vimkind",
    dependencies = { "mfussenegger/nvim-dap", module = "dap" },
    module = "osv",
  }, -- debug lua files
}
