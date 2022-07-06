-- docs -> https://github.com/wbthomason/packer.nvim
--
-- install packer -> git clone --depth 1 https://github.com/wbthomason/packer.nvim ~/.local/share/nvim/site/pack/packer/start/packer.nvim

-- options
-- run = runs shell command on install/update
-- cmd = nvim commands made from plugin
-- branch = use specific branch
-- config = plugin's configuration

-- Local plugins can be included
-- use '~/projects/personal/hover.nvim'

local disabled_builtins = {
    "gzip",
    "zip",
    "zipPlugin",
    "tar",
    "tarPlugin",
    "getscript",
    "getscriptPlugin",
    "vimball",
    "vimballPlugin",
    "2html_plugin",
    "logipat",
    "rrhelper",
    "spellfile_plugin",
}

for _, plugin in pairs(disabled_builtins) do
    vim.g["loaded_" .. plugin] = 1
end

local function req(module)
    return string.format('require("%s")', module)
end

return require("packer").startup({
    function(use)
        use({ "wbthomason/packer.nvim" })
        use {
            "ellisonleao/gruvbox.nvim",
            config = req("config.appearance.themes.gruvbox")
        }
        -- use({
        --     "folke/tokyonight.nvim",
        -- branch = "main",
        -- config = req("config.appearance.themes.tokyonight"),
        -- })
        use({
            "nvim-lualine/lualine.nvim",
            requires = { "kyazdani42/nvim-web-devicons", opt = true },
            config = req("config.appearance.lualine"),
        })

        use({
            "neovim/nvim-lspconfig",
            requires = {
                "williamboman/nvim-lsp-installer",
            },
            config = req("lsp.lsp"),
        })

        use({
            "SirVer/ultisnips",
            config = req("lsp.ultisnips"),
            requires = "quangnguyen30192/cmp-nvim-ultisnips",
        })
        use("honza/vim-snippets")

        -- use({
        --     "L3MON4D3/LuaSnip"
        -- })
        --
        -- use({ "windwp/nvim-autopairs", config = req("core.autopairs") }) -- no one key
        -- fastwrap
        use({
            "ray-x/lsp_signature.nvim",
            config = req("lsp.lsp-signature"),
        })
        use({
            "hrsh7th/nvim-cmp",
            requires = {
                "onsails/lspkind-nvim",
                "hrsh7th/cmp-nvim-lsp",
                { "hrsh7th/cmp-nvim-lua", ft = "lua" },
                "hrsh7th/cmp-path",
                "hrsh7th/cmp-buffer",
                -- "saadparwaiz1/cmp_luasnip",
                { "quangnguyen30192/cmp-nvim-ultisnips" },
            },
            config = req("lsp.cmp"),
        })

        use({
            "jose-elias-alvarez/null-ls.nvim",
            requires = { "nvim-lua/plenary.nvim", module_pattern = "plenary" },
            config = req("lsp.formatters"),
        })

        use({
            "nvim-telescope/telescope.nvim",
            requires = {
                "nvim-lua/plenary.nvim",
                { "nvim-telescope/telescope-fzf-native.nvim", run = "make" },
            },
            config = req("core.telescope"),
        })

        use({
            "nvim-treesitter/nvim-treesitter",
            run = ":TSUpdate",
            config = req("core.treesitter"),
        })

        use({
            "nvim-treesitter/playground",
            requires = "nvim-treesitter/nvim-treesitter",
            cmd = { "TSPlaygroundToggle", "TSHighlightCapturesUnderCursor" },
        })

        use({
            "ahmedkhalf/project.nvim",
            requires = "nvim-telescope/telescope.nvim",
            config = req("lsp.project"),
        })
        use({
            "numToStr/Comment.nvim",
            config = req("core.comment"),
        })

        -- Lazy loading:
        -- Load on specific commands
        use({
            "tpope/vim-dispatch",
            cmd = { "Dispatch", "Make", "Focus", "Start" },
            ft = { "sh", "python", "c", "cpp", "js", "ts", "rs", "go" }, -- test for no filetype
        })

        use({
            "kyazdani42/nvim-tree.lua",
            requires = { "kyazdani42/nvim-web-devicons", opt = true }, -- optional, for file icons
            config = req("core.nvim-tree"),
            cmd = { "NvimTreeToggle", "NvimTreeOpen" },
        })

        use({
            "ThePrimeagen/harpoon",
            requires = { "nvim-lua/plenary.nvim", module_pattern = "plenary" },
            config = req("core.harpoon"),
            module = "harpoon",
        })

        use({
            "phaazon/hop.nvim",
            branch = "v1", -- optional but strongly recommended
            config = function()
                require("hop").setup({ keys = "etovxqpdygfblzhckisuran" })
            end,
            cmd = { "HopChar1" },
        })

        use({
            "mfussenegger/nvim-dap",
            requires = {
                { "Pocco81/DAPInstall.nvim", module = "dap-install" },
                { "rcarriga/nvim-dap-ui", module = "dapui" },
                { "theHamsta/nvim-dap-virtual-text", module = "nvim-dap-virtual-text" },
            },
            module = "dap",
            config = req("lsp.dap"),
        })

        use({
            "jbyuki/one-small-step-for-vimkind",
            requires = "mfussenegger/nvim-dap",
            module = "osv",
        }) -- debug lua files

        -- add gitsigns

        use({
            "github/copilot.vim",
            config = function()
                vim.g.copilot_enabled = false
                vim.g.copilot_filetypes = { xml = false }
                vim.g.copilot_no_tab_map = true
            end,
            cmd = "Copilot",
        })

        use({
            "wellle/targets.vim",
            config = function()
                vim.g.targets_aiAI = { "a", "l", "A", "L" }
                vim.g.targets_mapped_aiAI = { "a", "i", "A", "I" }
                vim.g.targets_nl = { "n", "N" }
                -- this script lets you apply macros to multiple lines
                vim.cmd("source ~/.config/nvim/modules/visual-at.vim")
            end,
        })
        use("tpope/vim-repeat")
        use("tommcdo/vim-exchange")
        use("tpope/vim-surround")
        use("kana/vim-textobj-user")
        use({
            "kana/vim-textobj-line",
            config = function()
                vim.g.textobj_line_no_default_key_mappings = 1
            end,
        })
        use({
            "kana/vim-textobj-entire",
            config = function()
                vim.g.textobj_entire_no_default_key_mappings = 1
            end,
        })

        -- meh
        use({
            "plasticboy/vim-markdown",
            requires = "godlygeek/tabular",
            ft = "md",
        })
        --

        use({
            "folke/which-key.nvim",
            config = req("config.appearance.whichkey"),
        })
        use({
            "yggdroot/indentLine",
            config = function()
                vim.g.indentLine_char = "┆"
                vim.g.indentLine_enabled = 0
                -- show double quotes in json
                -- vim.o.concealLevel = 0
            end,
        })
        use({
            "Pocco81/TrueZen.nvim",
            config = req("core.truezen"),
            cmd = { "TZMinimalist", "TZFocus", "TZAtaraxis" },
        })

        use({
            "mbbill/undotree",
            cmd = { "UndotreeToggle" },
        })

        -- use("inkarkat/vim-ReplaceWithRegister")

        use({ "preservim/tagbar", cmd = { "TagbarToggle" } })
        -- --------------------
        use({
            "mattn/emmet-vim",
            config = function()
                vim.g.user_emmet_install_global = 0
            end,
            ft = { "html", "js", "ts", "css", "vue", "svelte", "jsx", "tsx" },
        })
        use({
            "alvan/vim-closetag",
            config = req("core.closetags"),
            ft = { "html", "js", "ts", "css", "vue", "svelte", "jsx", "tsx" },
        })

        -- use({
        --     "LunarWatcher/auto-pairs",
        --     config = req("core.autopairs"),
        -- })
        use({
            "windwp/nvim-autopairs",
            config = req("core.autopairs2"),
        })

        use({
            "tpope/vim-projectionist",
            requires = "neovim/nvim-lspconfig",
            -- breaks <leader>si
            -- needs to start for skel files
            -- cond = function()
            --     return require("lspconfig.util").root_pattern(".projections.json")(vim.fn.getcwd()) ~= nil
            -- end,
        })

        -- check if there is a file .env
        use({
            "tpope/vim-dotenv",
            requires = "neovim/nvim-lspconfig",
            cond = function()
                return require("lspconfig.util").root_pattern(".env*")(vim.fn.getcwd()) ~= nil
            end,
        })
        -- fun
        use({ "ThePrimeagen/vim-apm", cmd = { "VimApm" } })
        use({
            "ThePrimeagen/vim-be-good",
            cmd = { "VimBeGood" },
        })
        use({
            "ThePrimeagen/git-worktree.nvim",
        })
        use({
            "lewis6991/gitsigns.nvim",
            requires = { "nvim-lua/plenary.nvim" },
            config = req("core.gitsigns"),
            cond = function()
                return require("lspconfig.util").root_pattern(".git")(vim.fn.getcwd()) ~= nil
            end,
        })

        use("bkad/CamelCaseMotion")
        use({
            "editorconfig/editorconfig-vim",
            config = function()
                vim.g.EditorConfig_exclude_patterns = { "fugitive://.*" }
            end,
            cond = function()
                return require("lspconfig.util").root_pattern(".editorconfig")(vim.fn.getcwd()) ~= nil
            end,
        })
        use({ "bps/vim-textobj-python", ft = "python" })
        use("glts/vim-textobj-comment")

        use({
            "AndrewRadev/splitjoin.vim",
            config = function()
                vim.g.splitjoin_split_mapping = "gs"
                vim.g.splitjoin_join_mapping = "gS"
            end,
        })
        use({
            "matze/vim-move",
            config = function()
                vim.g.move_key_modifier = "C"
                vim.g.move_map_keys = 0
            end,
        }) --to do operations on visual mode

        use({
            "szw/vim-maximizer",
            cmd = "MaximizerToggle",
            config = function()
                vim.g.maximizer_set_default_mapping = 0
            end,
        })

        -- :h vis commands for visual selection
        use("vim-scripts/vis")

        use({ "osyo-manga/vim-brightest", cmd = "BrightestToggle" })

        use({ "junegunn/gv.vim", cmd = "GV" })

        use({
            "rbgrouleff/bclose.vim",
            cmd = "Bclose",
            config = function()
                --The :Bclose command deletes a buffer without changing the window layout, unlike :bd.
                vim.g.bclose_no_plugin_maps = 1
            end,
        })

        use({
            "frazrepo/vim-rainbow",
            cmd = "RainbowToggle",
            config = function()
                vim.g.rainbow_active = 0
            end,
        })

        use({
            "tpope/vim-fugitive",
            requires = "tpope/vim-rhubarb",
            config = function()
                vim.opt.diffopt = "internal,vertical,closeoff,filler"
            end,
        })
        use({
            "tpope/vim-obsession",
            cmd = { "Obsession", "Obsession!" },
            config = function()
                vim.g.obsession_no_bufenter = 1
                vim.opt.statusline = "%{ObsessionStatus()}"
            end,
        })
        use({
            "vim-test/vim-test",
            config = req("core.vim-test"),
            cmd = {
                "TestNearest",
                "TestFile",
                "TestSuite",
                "TestVisit",
            },
        })
        use({ "brooth/far.vim", cmd = { "Far", "Fardo", "Farr" } })
        use({
            "ThePrimeagen/refactoring.nvim",
            requires = {
                { "nvim-lua/plenary.nvim" },
                { "nvim-treesitter/nvim-treesitter" },
            },
            config = req("core.refactoring")
        })

        use({ "rcarriga/nvim-notify", config = req("core.notify"), module = "notify" })

        use({ "michaelb/sniprun", run = "bash ./install.sh", config = req("core.sniprun"), cmd = "SnipRun" })
        use({
            "pwntester/octo.nvim",
            requires = {
                "nvim-lua/plenary.nvim",
                "nvim-telescope/telescope.nvim",
                "kyazdani42/nvim-web-devicons",
            },
            cmd = "Octo",
            config = req("core.octo"),
        })

        use({ "Vimjas/vim-python-pep8-indent" }) -- for indentation, treesitter not functional yet 23/01/2022
        use({
            "nvim-orgmode/orgmode",
            config = function()
                require("orgmode").setup({})
                require("orgmode").setup_ts_grammar()
            end,
        })

        -- check arpeggio https://github.com/kana/vim-arpeggio
        -- check sideways https://github.com/AndrewRadev/sideways.vim

        -- not working with sshconfig as of 13 jan 2021
        -- use({
        --     "chipsenkbeil/distant.nvim",
        --     config = function()
        --         require("distant").setup({
        --             -- Applies Chip's personal settings to every machine you connect to
        --             --
        --             -- 1. Ensures that distant servers terminate with no connections
        --             -- 2. Provides navigation bindings for remote directories
        --             -- 3. Provides keybinding to jump into a remote file's parent directory
        --             ["*"] = require("distant.settings").chip_default(),
        --         })
        --     end,
        -- })

        -- colors
        -- use("gruvbox-community/gruvbox")
        -- use("dracula/vim")
        -- use("crusoexia/vim-monokai")
    end,
    config = {
        display = {
            open_fn = function()
                return require("packer.util").float({ border = "single" })
            end,
        },
    },
})
