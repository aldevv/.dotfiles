local function req(module)
  return function(name, opts)
    require(module)
  end
end

return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      {
        "rcarriga/nvim-dap-ui",
        dependencies = { "nvim-neotest/nvim-nio" },
      },
      { "theHamsta/nvim-dap-virtual-text" },
      { "nvim-telescope/telescope-dap.nvim" },
      { "mfussenegger/nvim-dap-python" },
      { "leoluz/nvim-dap-go" },
      "williamboman/mason.nvim",
    },
    -- lazy.nvim's `module` field was deprecated; dependencies are
    -- pulled in on demand by the `require` calls inside config.
    config = req("config.plugins.dap.dap"),
  },
  "jayp0521/mason-nvim-dap.nvim",
  {
    "jbyuki/one-small-step-for-vimkind",
    dependencies = { "mfussenegger/nvim-dap" },
  }, -- debug lua files
}
