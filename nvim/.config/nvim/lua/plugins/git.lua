local function req(module)
  return function(name, opts)
    require(module)
  end
end
return {
  "ThePrimeagen/git-worktree.nvim",
  {
    "tpope/vim-fugitive",
    dependencies = { "tpope/vim-rhubarb" },
    config = function()
      vim.opt.diffopt = "internal,vertical,closeoff,filler"
    end,
  },
  { "junegunn/gv.vim", cmd = "GV" },
}
