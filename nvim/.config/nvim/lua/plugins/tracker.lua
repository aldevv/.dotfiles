local function req(module)
  return function(name, opts)
    require(module)
  end
end

return {
  {
    "aldevv/plugin-tracker.nvim",
    dev = true,
    lazy = false,
    priority = 10000,
    config = req("config.plugins.plugin-tracker"),
  },
}
