local function req(module)
  return function(name, opts)
    require(module)
  end
end
return {
  "ThePrimeagen/git-worktree.nvim",
  {
    "tpope/vim-fugitive",
    config = function()
      vim.opt.diffopt = "internal,vertical,closeoff,filler"
    end,
  },
  { "junegunn/gv.vim", cmd = "GV" },
  {
    "lewis6991/gitsigns.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = req("config.plugins.gitsigns"),
  },
}
