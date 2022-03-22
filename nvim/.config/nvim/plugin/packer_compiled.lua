-- Automatically generated packer.nvim plugin loader code

if vim.api.nvim_call_function('has', {'nvim-0.5'}) ~= 1 then
  vim.api.nvim_command('echohl WarningMsg | echom "Invalid Neovim version for packer.nvim! | echohl None"')
  return
end

vim.api.nvim_command('packadd packer.nvim')

local no_errors, error_msg = pcall(function()

  local time
  local profile_info
  local should_profile = false
  if should_profile then
    local hrtime = vim.loop.hrtime
    profile_info = {}
    time = function(chunk, start)
      if start then
        profile_info[chunk] = hrtime()
      else
        profile_info[chunk] = (hrtime() - profile_info[chunk]) / 1e6
      end
    end
  else
    time = function(chunk, start) end
  end
  
local function save_profiles(threshold)
  local sorted_times = {}
  for chunk_name, time_taken in pairs(profile_info) do
    sorted_times[#sorted_times + 1] = {chunk_name, time_taken}
  end
  table.sort(sorted_times, function(a, b) return a[2] > b[2] end)
  local results = {}
  for i, elem in ipairs(sorted_times) do
    if not threshold or threshold and elem[2] > threshold then
      results[i] = elem[1] .. ' took ' .. elem[2] .. 'ms'
    end
  end

  _G._packer = _G._packer or {}
  _G._packer.profile_output = results
end

time([[Luarocks path setup]], true)
local package_path_str = "/home/kanon/.cache/nvim/packer_hererocks/2.1.0-beta3/share/lua/5.1/?.lua;/home/kanon/.cache/nvim/packer_hererocks/2.1.0-beta3/share/lua/5.1/?/init.lua;/home/kanon/.cache/nvim/packer_hererocks/2.1.0-beta3/lib/luarocks/rocks-5.1/?.lua;/home/kanon/.cache/nvim/packer_hererocks/2.1.0-beta3/lib/luarocks/rocks-5.1/?/init.lua"
local install_cpath_pattern = "/home/kanon/.cache/nvim/packer_hererocks/2.1.0-beta3/lib/lua/5.1/?.so"
if not string.find(package.path, package_path_str, 1, true) then
  package.path = package.path .. ';' .. package_path_str
end

if not string.find(package.cpath, install_cpath_pattern, 1, true) then
  package.cpath = package.cpath .. ';' .. install_cpath_pattern
end

time([[Luarocks path setup]], false)
time([[try_loadstring definition]], true)
local function try_loadstring(s, component, name)
  local success, result = pcall(loadstring(s), name, _G.packer_plugins[name])
  if not success then
    vim.schedule(function()
      vim.api.nvim_notify('packer.nvim: Error running ' .. component .. ' for ' .. name .. ': ' .. result, vim.log.levels.ERROR, {})
    end)
  end
  return result
end

time([[try_loadstring definition]], false)
time([[Defining packer_plugins]], true)
_G.packer_plugins = {
  CamelCaseMotion = {
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/CamelCaseMotion",
    url = "https://github.com/bkad/CamelCaseMotion"
  },
  ["Comment.nvim"] = {
    config = { 'require("core.comment")' },
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/Comment.nvim",
    url = "https://github.com/numToStr/Comment.nvim"
  },
  ["DAPInstall.nvim"] = {
    loaded = false,
    needs_bufread = false,
    only_cond = false,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/opt/DAPInstall.nvim",
    url = "https://github.com/Pocco81/DAPInstall.nvim"
  },
  ["TrueZen.nvim"] = {
    commands = { "TZMinimalist", "TZFocus", "TZAtaraxis" },
    config = { 'require("core.truezen")' },
    loaded = false,
    needs_bufread = false,
    only_cond = false,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/opt/TrueZen.nvim",
    url = "https://github.com/Pocco81/TrueZen.nvim"
  },
  ["bclose.vim"] = {
    commands = { "Bclose" },
    config = { "\27LJ\2\n7\0\0\2\0\3\0\0056\0\0\0009\0\1\0)\1\1\0=\1\2\0K\0\1\0\26bclose_no_plugin_maps\6g\bvim\0" },
    loaded = false,
    needs_bufread = false,
    only_cond = false,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/opt/bclose.vim",
    url = "https://github.com/rbgrouleff/bclose.vim"
  },
  ["cmp-buffer"] = {
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/cmp-buffer",
    url = "https://github.com/hrsh7th/cmp-buffer"
  },
  ["cmp-nvim-lsp"] = {
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/cmp-nvim-lsp",
    url = "https://github.com/hrsh7th/cmp-nvim-lsp"
  },
  ["cmp-nvim-lua"] = {
    after_files = { "/home/kanon/.local/share/nvim/site/pack/packer/opt/cmp-nvim-lua/after/plugin/cmp_nvim_lua.lua" },
    loaded = false,
    needs_bufread = false,
    only_cond = false,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/opt/cmp-nvim-lua",
    url = "https://github.com/hrsh7th/cmp-nvim-lua"
  },
  ["cmp-nvim-ultisnips"] = {
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/cmp-nvim-ultisnips",
    url = "https://github.com/quangnguyen30192/cmp-nvim-ultisnips"
  },
  ["cmp-path"] = {
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/cmp-path",
    url = "https://github.com/hrsh7th/cmp-path"
  },
  ["copilot.vim"] = {
    commands = { "Copilot" },
    config = { "\27LJ\2\n~\0\0\2\0\6\0\r6\0\0\0009\0\1\0+\1\1\0=\1\2\0006\0\0\0009\0\1\0005\1\4\0=\1\3\0006\0\0\0009\0\1\0+\1\2\0=\1\5\0K\0\1\0\23copilot_no_tab_map\1\0\1\bxml\1\22copilot_filetypes\20copilot_enabled\6g\bvim\0" },
    loaded = false,
    needs_bufread = false,
    only_cond = false,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/opt/copilot.vim",
    url = "https://github.com/github/copilot.vim"
  },
  ["editorconfig-vim"] = {
    cond = { "\27LJ\2\n‹\1\0\0\4\0\a\0\0176\0\0\0'\2\1\0B\0\2\0029\0\2\0'\2\3\0B\0\2\0026\2\4\0009\2\5\0029\2\6\2B\2\1\0A\0\0\2\v\0\0\0X\0\2€+\0\1\0X\1\1€+\0\2\0L\0\2\0\vgetcwd\afn\bvim\18.editorconfig\17root_pattern\19lspconfig.util\frequire\0" },
    config = { '\27LJ\2\nQ\0\0\2\0\4\0\0056\0\0\0009\0\1\0005\1\3\0=\1\2\0K\0\1\0\1\2\0\0\18fugitive://.*"EditorConfig_exclude_patterns\6g\bvim\0' },
    loaded = false,
    needs_bufread = false,
    only_cond = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/opt/editorconfig-vim",
    url = "https://github.com/editorconfig/editorconfig-vim"
  },
  ["emmet-vim"] = {
    config = { "\27LJ\2\n;\0\0\2\0\3\0\0056\0\0\0009\0\1\0)\1\0\0=\1\2\0K\0\1\0\30user_emmet_install_global\6g\bvim\0" },
    loaded = false,
    needs_bufread = false,
    only_cond = false,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/opt/emmet-vim",
    url = "https://github.com/mattn/emmet-vim"
  },
  ["far.vim"] = {
    commands = { "Far", "Fardo", "Farr" },
    loaded = false,
    needs_bufread = false,
    only_cond = false,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/opt/far.vim",
    url = "https://github.com/brooth/far.vim"
  },
  ["git-worktree.nvim"] = {
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/git-worktree.nvim",
    url = "https://github.com/ThePrimeagen/git-worktree.nvim"
  },
  ["gitsigns.nvim"] = {
    cond = { "\27LJ\2\n‚\1\0\0\4\0\a\0\0176\0\0\0'\2\1\0B\0\2\0029\0\2\0'\2\3\0B\0\2\0026\2\4\0009\2\5\0029\2\6\2B\2\1\0A\0\0\2\v\0\0\0X\0\2€+\0\1\0X\1\1€+\0\2\0L\0\2\0\vgetcwd\afn\bvim\t.git\17root_pattern\19lspconfig.util\frequire\0" },
    config = { 'require("core.gitsigns")' },
    loaded = false,
    needs_bufread = false,
    only_cond = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/opt/gitsigns.nvim",
    url = "https://github.com/lewis6991/gitsigns.nvim"
  },
  ["gv.vim"] = {
    commands = { "GV" },
    loaded = false,
    needs_bufread = false,
    only_cond = false,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/opt/gv.vim",
    url = "https://github.com/junegunn/gv.vim"
  },
  harpoon = {
    config = { 'require("core.harpoon")' },
    loaded = false,
    needs_bufread = false,
    only_cond = false,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/opt/harpoon",
    url = "https://github.com/ThePrimeagen/harpoon"
  },
  ["hop.nvim"] = {
    commands = { "HopChar1" },
    config = { "\27LJ\2\nU\0\0\3\0\4\0\a6\0\0\0'\2\1\0B\0\2\0029\0\2\0005\2\3\0B\0\2\1K\0\1\0\1\0\1\tkeys\28etovxqpdygfblzhckisuran\nsetup\bhop\frequire\0" },
    loaded = false,
    needs_bufread = false,
    only_cond = false,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/opt/hop.nvim",
    url = "https://github.com/phaazon/hop.nvim"
  },
  indentLine = {
    config = { "\27LJ\2\nX\0\0\2\0\5\0\t6\0\0\0009\0\1\0'\1\3\0=\1\2\0006\0\0\0009\0\1\0)\1\0\0=\1\4\0K\0\1\0\23indentLine_enabled\bâ”†\20indentLine_char\6g\bvim\0" },
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/indentLine",
    url = "https://github.com/yggdroot/indentLine"
  },
  ["lsp_signature.nvim"] = {
    config = { 'require("lsp.lsp-signature")' },
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/lsp_signature.nvim",
    url = "https://github.com/ray-x/lsp_signature.nvim"
  },
  ["lspkind-nvim"] = {
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/lspkind-nvim",
    url = "https://github.com/onsails/lspkind-nvim"
  },
  ["lualine.nvim"] = {
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/lualine.nvim",
    url = "https://github.com/nvim-lualine/lualine.nvim"
  },
  ["null-ls.nvim"] = {
    config = { 'require("lsp.formatters")' },
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/null-ls.nvim",
    url = "https://github.com/jose-elias-alvarez/null-ls.nvim"
  },
  ["nvim-autopairs"] = {
    config = { 'require("core.autopairs2")' },
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/nvim-autopairs",
    url = "https://github.com/windwp/nvim-autopairs"
  },
  ["nvim-cmp"] = {
    config = { 'require("lsp.cmp")' },
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/nvim-cmp",
    url = "https://github.com/hrsh7th/nvim-cmp"
  },
  ["nvim-dap"] = {
    config = { 'require("lsp.dap")' },
    loaded = false,
    needs_bufread = false,
    only_cond = false,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/opt/nvim-dap",
    url = "https://github.com/mfussenegger/nvim-dap"
  },
  ["nvim-dap-ui"] = {
    loaded = false,
    needs_bufread = false,
    only_cond = false,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/opt/nvim-dap-ui",
    url = "https://github.com/rcarriga/nvim-dap-ui"
  },
  ["nvim-dap-virtual-text"] = {
    loaded = false,
    needs_bufread = false,
    only_cond = false,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/opt/nvim-dap-virtual-text",
    url = "https://github.com/theHamsta/nvim-dap-virtual-text"
  },
  ["nvim-lsp-installer"] = {
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/nvim-lsp-installer",
    url = "https://github.com/williamboman/nvim-lsp-installer"
  },
  ["nvim-lspconfig"] = {
    config = { 'require("lsp")' },
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/nvim-lspconfig",
    url = "https://github.com/neovim/nvim-lspconfig"
  },
  ["nvim-notify"] = {
    config = { 'require("core.notify")' },
    loaded = false,
    needs_bufread = false,
    only_cond = false,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/opt/nvim-notify",
    url = "https://github.com/rcarriga/nvim-notify"
  },
  ["nvim-tree.lua"] = {
    commands = { "NvimTreeToggle", "NvimTreeOpen" },
    config = { 'require("core.nvim-tree")' },
    loaded = false,
    needs_bufread = false,
    only_cond = false,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/opt/nvim-tree.lua",
    url = "https://github.com/kyazdani42/nvim-tree.lua"
  },
  ["nvim-treesitter"] = {
    config = { 'require("core.treesitter")' },
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/nvim-treesitter",
    url = "https://github.com/nvim-treesitter/nvim-treesitter"
  },
  ["nvim-web-devicons"] = {
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/nvim-web-devicons",
    url = "https://github.com/kyazdani42/nvim-web-devicons"
  },
  ["octo.nvim"] = {
    commands = { "Octo" },
    config = { 'require("core.octo")' },
    loaded = false,
    needs_bufread = false,
    only_cond = false,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/opt/octo.nvim",
    url = "https://github.com/pwntester/octo.nvim"
  },
  ["one-small-step-for-vimkind"] = {
    loaded = false,
    needs_bufread = false,
    only_cond = false,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/opt/one-small-step-for-vimkind",
    url = "https://github.com/jbyuki/one-small-step-for-vimkind"
  },
  orgmode = {
    config = { "\27LJ\2\n9\0\0\3\0\3\0\a6\0\0\0'\2\1\0B\0\2\0029\0\2\0004\2\0\0B\0\2\1K\0\1\0\nsetup\forgmode\frequire\0" },
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/orgmode",
    url = "https://github.com/nvim-orgmode/orgmode"
  },
  ["packer.nvim"] = {
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/packer.nvim",
    url = "https://github.com/wbthomason/packer.nvim"
  },
  playground = {
    commands = { "TSPlaygroundToggle", "TSHighlightCapturesUnderCursor" },
    loaded = false,
    needs_bufread = true,
    only_cond = false,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/opt/playground",
    url = "https://github.com/nvim-treesitter/playground"
  },
  ["plenary.nvim"] = {
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/plenary.nvim",
    url = "https://github.com/nvim-lua/plenary.nvim"
  },
  ["project.nvim"] = {
    config = { 'require("lsp.project")' },
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/project.nvim",
    url = "https://github.com/ahmedkhalf/project.nvim"
  },
  ["refactoring.nvim"] = {
    config = { 'require("lsp.refactoring")' },
    loaded = false,
    needs_bufread = false,
    only_cond = false,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/opt/refactoring.nvim",
    url = "https://github.com/ThePrimeagen/refactoring.nvim"
  },
  sniprun = {
    commands = { "SnipRun" },
    config = { 'require("core.sniprun")' },
    loaded = false,
    needs_bufread = false,
    only_cond = false,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/opt/sniprun",
    url = "https://github.com/michaelb/sniprun"
  },
  ["splitjoin.vim"] = {
    config = { "\27LJ\2\nf\0\0\2\0\6\0\t6\0\0\0009\0\1\0'\1\3\0=\1\2\0006\0\0\0009\0\1\0'\1\5\0=\1\4\0K\0\1\0\agS\27splitjoin_join_mapping\ags\28splitjoin_split_mapping\6g\bvim\0" },
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/splitjoin.vim",
    url = "https://github.com/AndrewRadev/splitjoin.vim"
  },
  tabular = {
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/tabular",
    url = "https://github.com/godlygeek/tabular"
  },
  tagbar = {
    commands = { "TagbarToggle" },
    loaded = false,
    needs_bufread = false,
    only_cond = false,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/opt/tagbar",
    url = "https://github.com/preservim/tagbar"
  },
  ["targets.vim"] = {
    config = { "\27LJ\2\nÍ\1\0\0\3\0\n\0\0176\0\0\0009\0\1\0005\1\3\0=\1\2\0006\0\0\0009\0\1\0005\1\5\0=\1\4\0006\0\0\0009\0\1\0005\1\a\0=\1\6\0006\0\0\0009\0\b\0'\2\t\0B\0\2\1K\0\1\0000source ~/.config/nvim/modules/visual-at.vim\bcmd\1\3\0\0\6n\6N\15targets_nl\1\5\0\0\6a\6i\6A\6I\24targets_mapped_aiAI\1\5\0\0\6a\6l\6A\6L\17targets_aiAI\6g\bvim\0" },
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/targets.vim",
    url = "https://github.com/wellle/targets.vim"
  },
  ["telescope-fzf-native.nvim"] = {
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/telescope-fzf-native.nvim",
    url = "https://github.com/nvim-telescope/telescope-fzf-native.nvim"
  },
  ["telescope.nvim"] = {
    config = { 'require("core.telescope")' },
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/telescope.nvim",
    url = "https://github.com/nvim-telescope/telescope.nvim"
  },
  ["tokyonight.nvim"] = {
    config = { 'require("config.appearance.themes.tokyonight")' },
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/tokyonight.nvim",
    url = "https://github.com/folke/tokyonight.nvim"
  },
  ultisnips = {
    config = { 'require("lsp.ultisnips")' },
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/ultisnips",
    url = "https://github.com/SirVer/ultisnips"
  },
  undotree = {
    commands = { "UndotreeToggle" },
    loaded = false,
    needs_bufread = false,
    only_cond = false,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/opt/undotree",
    url = "https://github.com/mbbill/undotree"
  },
  ["vim-apm"] = {
    commands = { "VimApm" },
    loaded = false,
    needs_bufread = false,
    only_cond = false,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/opt/vim-apm",
    url = "https://github.com/ThePrimeagen/vim-apm"
  },
  ["vim-be-good"] = {
    commands = { "VimBeGood" },
    loaded = false,
    needs_bufread = false,
    only_cond = false,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/opt/vim-be-good",
    url = "https://github.com/ThePrimeagen/vim-be-good"
  },
  ["vim-brightest"] = {
    commands = { "BrightestToggle" },
    loaded = false,
    needs_bufread = false,
    only_cond = false,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/opt/vim-brightest",
    url = "https://github.com/osyo-manga/vim-brightest"
  },
  ["vim-closetag"] = {
    config = { 'require("core.closetags")' },
    loaded = false,
    needs_bufread = false,
    only_cond = false,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/opt/vim-closetag",
    url = "https://github.com/alvan/vim-closetag"
  },
  ["vim-dispatch"] = {
    commands = { "Dispatch", "Make", "Focus", "Start" },
    loaded = false,
    needs_bufread = false,
    only_cond = false,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/opt/vim-dispatch",
    url = "https://github.com/tpope/vim-dispatch"
  },
  ["vim-dotenv"] = {
    cond = { "\27LJ\2\nƒ\1\0\0\4\0\a\0\0176\0\0\0'\2\1\0B\0\2\0029\0\2\0'\2\3\0B\0\2\0026\2\4\0009\2\5\0029\2\6\2B\2\1\0A\0\0\2\v\0\0\0X\0\2€+\0\1\0X\1\1€+\0\2\0L\0\2\0\vgetcwd\afn\bvim\n.env*\17root_pattern\19lspconfig.util\frequire\0" },
    loaded = false,
    needs_bufread = false,
    only_cond = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/opt/vim-dotenv",
    url = "https://github.com/tpope/vim-dotenv"
  },
  ["vim-exchange"] = {
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/vim-exchange",
    url = "https://github.com/tommcdo/vim-exchange"
  },
  ["vim-fugitive"] = {
    config = { "\27LJ\2\nM\0\0\2\0\4\0\0056\0\0\0009\0\1\0'\1\3\0=\1\2\0K\0\1\0&internal,vertical,closeoff,filler\fdiffopt\bopt\bvim\0" },
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/vim-fugitive",
    url = "https://github.com/tpope/vim-fugitive"
  },
  ["vim-markdown"] = {
    loaded = false,
    needs_bufread = true,
    only_cond = false,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/opt/vim-markdown",
    url = "https://github.com/plasticboy/vim-markdown"
  },
  ["vim-maximizer"] = {
    commands = { "MaximizerToggle" },
    config = { '\27LJ\2\n?\0\0\2\0\3\0\0056\0\0\0009\0\1\0)\1\0\0=\1\2\0K\0\1\0"maximizer_set_default_mapping\6g\bvim\0' },
    loaded = false,
    needs_bufread = false,
    only_cond = false,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/opt/vim-maximizer",
    url = "https://github.com/szw/vim-maximizer"
  },
  ["vim-move"] = {
    config = { "\27LJ\2\nS\0\0\2\0\5\0\t6\0\0\0009\0\1\0'\1\3\0=\1\2\0006\0\0\0009\0\1\0)\1\0\0=\1\4\0K\0\1\0\18move_map_keys\6C\22move_key_modifier\6g\bvim\0" },
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/vim-move",
    url = "https://github.com/matze/vim-move"
  },
  ["vim-obsession"] = {
    commands = { "Obsession", "Obsession!" },
    config = { "\27LJ\2\nk\0\0\2\0\6\0\t6\0\0\0009\0\1\0)\1\1\0=\1\2\0006\0\0\0009\0\3\0'\1\5\0=\1\4\0K\0\1\0\25%{ObsessionStatus()}\15statusline\bopt\26obsession_no_bufenter\6g\bvim\0" },
    loaded = false,
    needs_bufread = false,
    only_cond = false,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/opt/vim-obsession",
    url = "https://github.com/tpope/vim-obsession"
  },
  ["vim-projectionist"] = {
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/vim-projectionist",
    url = "https://github.com/tpope/vim-projectionist"
  },
  ["vim-python-pep8-indent"] = {
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/vim-python-pep8-indent",
    url = "https://github.com/Vimjas/vim-python-pep8-indent"
  },
  ["vim-rainbow"] = {
    commands = { "RainbowToggle" },
    config = { "\27LJ\2\n0\0\0\2\0\3\0\0056\0\0\0009\0\1\0)\1\0\0=\1\2\0K\0\1\0\19rainbow_active\6g\bvim\0" },
    loaded = false,
    needs_bufread = false,
    only_cond = false,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/opt/vim-rainbow",
    url = "https://github.com/frazrepo/vim-rainbow"
  },
  ["vim-repeat"] = {
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/vim-repeat",
    url = "https://github.com/tpope/vim-repeat"
  },
  ["vim-rhubarb"] = {
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/vim-rhubarb",
    url = "https://github.com/tpope/vim-rhubarb"
  },
  ["vim-snippets"] = {
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/vim-snippets",
    url = "https://github.com/honza/vim-snippets"
  },
  ["vim-surround"] = {
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/vim-surround",
    url = "https://github.com/tpope/vim-surround"
  },
  ["vim-test"] = {
    commands = { "TestNearest", "TestFile", "TestSuite", "TestVisit" },
    config = { 'require("core.vim-test")' },
    loaded = false,
    needs_bufread = false,
    only_cond = false,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/opt/vim-test",
    url = "https://github.com/vim-test/vim-test"
  },
  ["vim-textobj-comment"] = {
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/vim-textobj-comment",
    url = "https://github.com/glts/vim-textobj-comment"
  },
  ["vim-textobj-entire"] = {
    config = { "\27LJ\2\nH\0\0\2\0\3\0\0056\0\0\0009\0\1\0)\1\1\0=\1\2\0K\0\1\0+textobj_entire_no_default_key_mappings\6g\bvim\0" },
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/vim-textobj-entire",
    url = "https://github.com/kana/vim-textobj-entire"
  },
  ["vim-textobj-line"] = {
    config = { "\27LJ\2\nF\0\0\2\0\3\0\0056\0\0\0009\0\1\0)\1\1\0=\1\2\0K\0\1\0)textobj_line_no_default_key_mappings\6g\bvim\0" },
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/vim-textobj-line",
    url = "https://github.com/kana/vim-textobj-line"
  },
  ["vim-textobj-python"] = {
    loaded = false,
    needs_bufread = true,
    only_cond = false,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/opt/vim-textobj-python",
    url = "https://github.com/bps/vim-textobj-python"
  },
  ["vim-textobj-user"] = {
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/vim-textobj-user",
    url = "https://github.com/kana/vim-textobj-user"
  },
  vis = {
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/vis",
    url = "https://github.com/vim-scripts/vis"
  },
  ["which-key.nvim"] = {
    config = { 'require("config.appearance.whichkey")' },
    loaded = true,
    path = "/home/kanon/.local/share/nvim/site/pack/packer/start/which-key.nvim",
    url = "https://github.com/folke/which-key.nvim"
  }
}

time([[Defining packer_plugins]], false)
local module_lazy_loads = {
  ["^dap"] = "nvim-dap",
  ["^dap%-install"] = "DAPInstall.nvim",
  ["^dapui"] = "nvim-dap-ui",
  ["^harpoon"] = "harpoon",
  ["^notify"] = "nvim-notify",
  ["^nvim%-dap%-virtual%-text"] = "nvim-dap-virtual-text",
  ["^osv"] = "one-small-step-for-vimkind",
  ["^refactoring"] = "refactoring.nvim"
}
local lazy_load_called = {['packer.load'] = true}
local function lazy_load_module(module_name)
  local to_load = {}
  if lazy_load_called[module_name] then return nil end
  lazy_load_called[module_name] = true
  for module_pat, plugin_name in pairs(module_lazy_loads) do
    if not _G.packer_plugins[plugin_name].loaded and string.match(module_name, module_pat) then
      to_load[#to_load + 1] = plugin_name
    end
  end

  if #to_load > 0 then
    require('packer.load')(to_load, {module = module_name}, _G.packer_plugins)
    local loaded_mod = package.loaded[module_name]
    if loaded_mod then
      return function(modname) return loaded_mod end
    end
  end
end

if not vim.g.packer_custom_loader_enabled then
  table.insert(package.loaders, 1, lazy_load_module)
  vim.g.packer_custom_loader_enabled = true
end

-- Config for: nvim-cmp
time([[Config for nvim-cmp]], true)
require("lsp.cmp")
time([[Config for nvim-cmp]], false)
-- Config for: vim-textobj-entire
time([[Config for vim-textobj-entire]], true)
try_loadstring("\27LJ\2\nH\0\0\2\0\3\0\0056\0\0\0009\0\1\0)\1\1\0=\1\2\0K\0\1\0+textobj_entire_no_default_key_mappings\6g\bvim\0", "config", "vim-textobj-entire")
time([[Config for vim-textobj-entire]], false)
-- Config for: project.nvim
time([[Config for project.nvim]], true)
require("lsp.project")
time([[Config for project.nvim]], false)
-- Config for: vim-textobj-line
time([[Config for vim-textobj-line]], true)
try_loadstring("\27LJ\2\nF\0\0\2\0\3\0\0056\0\0\0009\0\1\0)\1\1\0=\1\2\0K\0\1\0)textobj_line_no_default_key_mappings\6g\bvim\0", "config", "vim-textobj-line")
time([[Config for vim-textobj-line]], false)
-- Config for: vim-move
time([[Config for vim-move]], true)
try_loadstring("\27LJ\2\nS\0\0\2\0\5\0\t6\0\0\0009\0\1\0'\1\3\0=\1\2\0006\0\0\0009\0\1\0)\1\0\0=\1\4\0K\0\1\0\18move_map_keys\6C\22move_key_modifier\6g\bvim\0", "config", "vim-move")
time([[Config for vim-move]], false)
-- Config for: orgmode
time([[Config for orgmode]], true)
try_loadstring("\27LJ\2\n9\0\0\3\0\3\0\a6\0\0\0'\2\1\0B\0\2\0029\0\2\0004\2\0\0B\0\2\1K\0\1\0\nsetup\forgmode\frequire\0", "config", "orgmode")
time([[Config for orgmode]], false)
-- Config for: indentLine
time([[Config for indentLine]], true)
try_loadstring("\27LJ\2\nX\0\0\2\0\5\0\t6\0\0\0009\0\1\0'\1\3\0=\1\2\0006\0\0\0009\0\1\0)\1\0\0=\1\4\0K\0\1\0\23indentLine_enabled\bâ”†\20indentLine_char\6g\bvim\0", "config", "indentLine")
time([[Config for indentLine]], false)
-- Config for: nvim-lspconfig
time([[Config for nvim-lspconfig]], true)
require("lsp")
time([[Config for nvim-lspconfig]], false)
-- Config for: splitjoin.vim
time([[Config for splitjoin.vim]], true)
try_loadstring("\27LJ\2\nf\0\0\2\0\6\0\t6\0\0\0009\0\1\0'\1\3\0=\1\2\0006\0\0\0009\0\1\0'\1\5\0=\1\4\0K\0\1\0\agS\27splitjoin_join_mapping\ags\28splitjoin_split_mapping\6g\bvim\0", "config", "splitjoin.vim")
time([[Config for splitjoin.vim]], false)
-- Config for: nvim-treesitter
time([[Config for nvim-treesitter]], true)
require("core.treesitter")
time([[Config for nvim-treesitter]], false)
-- Config for: null-ls.nvim
time([[Config for null-ls.nvim]], true)
require("lsp.formatters")
time([[Config for null-ls.nvim]], false)
-- Config for: targets.vim
time([[Config for targets.vim]], true)
try_loadstring("\27LJ\2\nÍ\1\0\0\3\0\n\0\0176\0\0\0009\0\1\0005\1\3\0=\1\2\0006\0\0\0009\0\1\0005\1\5\0=\1\4\0006\0\0\0009\0\1\0005\1\a\0=\1\6\0006\0\0\0009\0\b\0'\2\t\0B\0\2\1K\0\1\0000source ~/.config/nvim/modules/visual-at.vim\bcmd\1\3\0\0\6n\6N\15targets_nl\1\5\0\0\6a\6i\6A\6I\24targets_mapped_aiAI\1\5\0\0\6a\6l\6A\6L\17targets_aiAI\6g\bvim\0", "config", "targets.vim")
time([[Config for targets.vim]], false)
-- Config for: Comment.nvim
time([[Config for Comment.nvim]], true)
require("core.comment")
time([[Config for Comment.nvim]], false)
-- Config for: vim-fugitive
time([[Config for vim-fugitive]], true)
try_loadstring("\27LJ\2\nM\0\0\2\0\4\0\0056\0\0\0009\0\1\0'\1\3\0=\1\2\0K\0\1\0&internal,vertical,closeoff,filler\fdiffopt\bopt\bvim\0", "config", "vim-fugitive")
time([[Config for vim-fugitive]], false)
-- Config for: which-key.nvim
time([[Config for which-key.nvim]], true)
require("config.appearance.whichkey")
time([[Config for which-key.nvim]], false)
-- Config for: telescope.nvim
time([[Config for telescope.nvim]], true)
require("core.telescope")
time([[Config for telescope.nvim]], false)
-- Config for: lsp_signature.nvim
time([[Config for lsp_signature.nvim]], true)
require("lsp.lsp-signature")
time([[Config for lsp_signature.nvim]], false)
-- Config for: tokyonight.nvim
time([[Config for tokyonight.nvim]], true)
require("config.appearance.themes.tokyonight")
time([[Config for tokyonight.nvim]], false)
-- Config for: nvim-autopairs
time([[Config for nvim-autopairs]], true)
require("core.autopairs2")
time([[Config for nvim-autopairs]], false)
-- Config for: ultisnips
time([[Config for ultisnips]], true)
require("lsp.ultisnips")
time([[Config for ultisnips]], false)
-- Conditional loads
time([[Conditional loading of vim-dotenv]], true)
  require("packer.load")({"vim-dotenv"}, {}, _G.packer_plugins)
time([[Conditional loading of vim-dotenv]], false)
time([[Conditional loading of editorconfig-vim]], true)
  require("packer.load")({"editorconfig-vim"}, {}, _G.packer_plugins)
time([[Conditional loading of editorconfig-vim]], false)
time([[Conditional loading of gitsigns.nvim]], true)
  require("packer.load")({"gitsigns.nvim"}, {}, _G.packer_plugins)
time([[Conditional loading of gitsigns.nvim]], false)

-- Command lazy-loads
time([[Defining lazy-load commands]], true)
pcall(vim.cmd, [[command -nargs=* -range -bang -complete=file SnipRun lua require("packer.load")({'sniprun'}, { cmd = "SnipRun", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args>, mods = "<mods>" }, _G.packer_plugins)]])
pcall(vim.cmd, [[command -nargs=* -range -bang -complete=file Octo lua require("packer.load")({'octo.nvim'}, { cmd = "Octo", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args>, mods = "<mods>" }, _G.packer_plugins)]])
pcall(vim.cmd, [[command -nargs=* -range -bang -complete=file MaximizerToggle lua require("packer.load")({'vim-maximizer'}, { cmd = "MaximizerToggle", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args>, mods = "<mods>" }, _G.packer_plugins)]])
pcall(vim.cmd, [[command -nargs=* -range -bang -complete=file TSPlaygroundToggle lua require("packer.load")({'playground'}, { cmd = "TSPlaygroundToggle", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args>, mods = "<mods>" }, _G.packer_plugins)]])
pcall(vim.cmd, [[command -nargs=* -range -bang -complete=file TSHighlightCapturesUnderCursor lua require("packer.load")({'playground'}, { cmd = "TSHighlightCapturesUnderCursor", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args>, mods = "<mods>" }, _G.packer_plugins)]])
pcall(vim.cmd, [[command -nargs=* -range -bang -complete=file BrightestToggle lua require("packer.load")({'vim-brightest'}, { cmd = "BrightestToggle", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args>, mods = "<mods>" }, _G.packer_plugins)]])
pcall(vim.cmd, [[command -nargs=* -range -bang -complete=file GV lua require("packer.load")({'gv.vim'}, { cmd = "GV", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args>, mods = "<mods>" }, _G.packer_plugins)]])
pcall(vim.cmd, [[command -nargs=* -range -bang -complete=file Bclose lua require("packer.load")({'bclose.vim'}, { cmd = "Bclose", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args>, mods = "<mods>" }, _G.packer_plugins)]])
pcall(vim.cmd, [[command -nargs=* -range -bang -complete=file Dispatch lua require("packer.load")({'vim-dispatch'}, { cmd = "Dispatch", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args>, mods = "<mods>" }, _G.packer_plugins)]])
pcall(vim.cmd, [[command -nargs=* -range -bang -complete=file Make lua require("packer.load")({'vim-dispatch'}, { cmd = "Make", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args>, mods = "<mods>" }, _G.packer_plugins)]])
pcall(vim.cmd, [[command -nargs=* -range -bang -complete=file Focus lua require("packer.load")({'vim-dispatch'}, { cmd = "Focus", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args>, mods = "<mods>" }, _G.packer_plugins)]])
pcall(vim.cmd, [[command -nargs=* -range -bang -complete=file Start lua require("packer.load")({'vim-dispatch'}, { cmd = "Start", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args>, mods = "<mods>" }, _G.packer_plugins)]])
pcall(vim.cmd, [[command -nargs=* -range -bang -complete=file TZMinimalist lua require("packer.load")({'TrueZen.nvim'}, { cmd = "TZMinimalist", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args>, mods = "<mods>" }, _G.packer_plugins)]])
pcall(vim.cmd, [[command -nargs=* -range -bang -complete=file TZFocus lua require("packer.load")({'TrueZen.nvim'}, { cmd = "TZFocus", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args>, mods = "<mods>" }, _G.packer_plugins)]])
pcall(vim.cmd, [[command -nargs=* -range -bang -complete=file TZAtaraxis lua require("packer.load")({'TrueZen.nvim'}, { cmd = "TZAtaraxis", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args>, mods = "<mods>" }, _G.packer_plugins)]])
pcall(vim.cmd, [[command -nargs=* -range -bang -complete=file UndotreeToggle lua require("packer.load")({'undotree'}, { cmd = "UndotreeToggle", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args>, mods = "<mods>" }, _G.packer_plugins)]])
pcall(vim.cmd, [[command -nargs=* -range -bang -complete=file NvimTreeToggle lua require("packer.load")({'nvim-tree.lua'}, { cmd = "NvimTreeToggle", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args>, mods = "<mods>" }, _G.packer_plugins)]])
pcall(vim.cmd, [[command -nargs=* -range -bang -complete=file TagbarToggle lua require("packer.load")({'tagbar'}, { cmd = "TagbarToggle", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args>, mods = "<mods>" }, _G.packer_plugins)]])
pcall(vim.cmd, [[command -nargs=* -range -bang -complete=file HopChar1 lua require("packer.load")({'hop.nvim'}, { cmd = "HopChar1", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args>, mods = "<mods>" }, _G.packer_plugins)]])
pcall(vim.cmd, [[command -nargs=* -range -bang -complete=file Obsession lua require("packer.load")({'vim-obsession'}, { cmd = "Obsession", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args>, mods = "<mods>" }, _G.packer_plugins)]])
pcall(vim.cmd, [[au CmdUndefined Obsession! ++once lua require"packer.load"({'vim-obsession'}, {}, _G.packer_plugins)]])
pcall(vim.cmd, [[command -nargs=* -range -bang -complete=file VimApm lua require("packer.load")({'vim-apm'}, { cmd = "VimApm", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args>, mods = "<mods>" }, _G.packer_plugins)]])
pcall(vim.cmd, [[command -nargs=* -range -bang -complete=file TestNearest lua require("packer.load")({'vim-test'}, { cmd = "TestNearest", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args>, mods = "<mods>" }, _G.packer_plugins)]])
pcall(vim.cmd, [[command -nargs=* -range -bang -complete=file TestFile lua require("packer.load")({'vim-test'}, { cmd = "TestFile", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args>, mods = "<mods>" }, _G.packer_plugins)]])
pcall(vim.cmd, [[command -nargs=* -range -bang -complete=file TestSuite lua require("packer.load")({'vim-test'}, { cmd = "TestSuite", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args>, mods = "<mods>" }, _G.packer_plugins)]])
pcall(vim.cmd, [[command -nargs=* -range -bang -complete=file TestVisit lua require("packer.load")({'vim-test'}, { cmd = "TestVisit", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args>, mods = "<mods>" }, _G.packer_plugins)]])
pcall(vim.cmd, [[command -nargs=* -range -bang -complete=file Copilot lua require("packer.load")({'copilot.vim'}, { cmd = "Copilot", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args>, mods = "<mods>" }, _G.packer_plugins)]])
pcall(vim.cmd, [[command -nargs=* -range -bang -complete=file Far lua require("packer.load")({'far.vim'}, { cmd = "Far", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args>, mods = "<mods>" }, _G.packer_plugins)]])
pcall(vim.cmd, [[command -nargs=* -range -bang -complete=file Fardo lua require("packer.load")({'far.vim'}, { cmd = "Fardo", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args>, mods = "<mods>" }, _G.packer_plugins)]])
pcall(vim.cmd, [[command -nargs=* -range -bang -complete=file Farr lua require("packer.load")({'far.vim'}, { cmd = "Farr", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args>, mods = "<mods>" }, _G.packer_plugins)]])
pcall(vim.cmd, [[command -nargs=* -range -bang -complete=file NvimTreeOpen lua require("packer.load")({'nvim-tree.lua'}, { cmd = "NvimTreeOpen", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args>, mods = "<mods>" }, _G.packer_plugins)]])
pcall(vim.cmd, [[command -nargs=* -range -bang -complete=file RainbowToggle lua require("packer.load")({'vim-rainbow'}, { cmd = "RainbowToggle", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args>, mods = "<mods>" }, _G.packer_plugins)]])
pcall(vim.cmd, [[command -nargs=* -range -bang -complete=file VimBeGood lua require("packer.load")({'vim-be-good'}, { cmd = "VimBeGood", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args>, mods = "<mods>" }, _G.packer_plugins)]])
time([[Defining lazy-load commands]], false)

vim.cmd [[augroup packer_load_aucmds]]
vim.cmd [[au!]]
  -- Filetype lazy-loads
time([[Defining lazy-load filetype autocommands]], true)
vim.cmd [[au FileType html ++once lua require("packer.load")({'vim-closetag', 'emmet-vim'}, { ft = "html" }, _G.packer_plugins)]]
vim.cmd [[au FileType css ++once lua require("packer.load")({'vim-closetag', 'emmet-vim'}, { ft = "css" }, _G.packer_plugins)]]
vim.cmd [[au FileType vue ++once lua require("packer.load")({'vim-closetag', 'emmet-vim'}, { ft = "vue" }, _G.packer_plugins)]]
vim.cmd [[au FileType js ++once lua require("packer.load")({'vim-closetag', 'emmet-vim', 'vim-dispatch'}, { ft = "js" }, _G.packer_plugins)]]
vim.cmd [[au FileType jsx ++once lua require("packer.load")({'vim-closetag', 'emmet-vim'}, { ft = "jsx" }, _G.packer_plugins)]]
vim.cmd [[au FileType tsx ++once lua require("packer.load")({'vim-closetag', 'emmet-vim'}, { ft = "tsx" }, _G.packer_plugins)]]
vim.cmd [[au FileType python ++once lua require("packer.load")({'vim-textobj-python', 'vim-dispatch'}, { ft = "python" }, _G.packer_plugins)]]
vim.cmd [[au FileType lua ++once lua require("packer.load")({'cmp-nvim-lua'}, { ft = "lua" }, _G.packer_plugins)]]
vim.cmd [[au FileType cpp ++once lua require("packer.load")({'vim-dispatch'}, { ft = "cpp" }, _G.packer_plugins)]]
vim.cmd [[au FileType rs ++once lua require("packer.load")({'vim-dispatch'}, { ft = "rs" }, _G.packer_plugins)]]
vim.cmd [[au FileType go ++once lua require("packer.load")({'vim-dispatch'}, { ft = "go" }, _G.packer_plugins)]]
vim.cmd [[au FileType c ++once lua require("packer.load")({'vim-dispatch'}, { ft = "c" }, _G.packer_plugins)]]
vim.cmd [[au FileType sh ++once lua require("packer.load")({'vim-dispatch'}, { ft = "sh" }, _G.packer_plugins)]]
vim.cmd [[au FileType ts ++once lua require("packer.load")({'vim-closetag', 'emmet-vim', 'vim-dispatch'}, { ft = "ts" }, _G.packer_plugins)]]
vim.cmd [[au FileType md ++once lua require("packer.load")({'vim-markdown'}, { ft = "md" }, _G.packer_plugins)]]
vim.cmd [[au FileType svelte ++once lua require("packer.load")({'vim-closetag', 'emmet-vim'}, { ft = "svelte" }, _G.packer_plugins)]]
time([[Defining lazy-load filetype autocommands]], false)
vim.cmd("augroup END")
vim.cmd [[augroup filetypedetect]]
time([[Sourcing ftdetect script at: /home/kanon/.local/share/nvim/site/pack/packer/opt/vim-markdown/ftdetect/markdown.vim]], true)
vim.cmd [[source /home/kanon/.local/share/nvim/site/pack/packer/opt/vim-markdown/ftdetect/markdown.vim]]
time([[Sourcing ftdetect script at: /home/kanon/.local/share/nvim/site/pack/packer/opt/vim-markdown/ftdetect/markdown.vim]], false)
vim.cmd("augroup END")
if should_profile then save_profiles() end

end)

if not no_errors then
  vim.api.nvim_command('echohl ErrorMsg | echom "Error in packer_compiled: '..error_msg..'" | echom "Please check your config for correctness" | echohl None')
end
