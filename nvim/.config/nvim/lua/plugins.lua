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

-- theme
local current_theme = "gruvbox"

return require("packer").startup({
    function(use)
        use({ "wbthomason/packer.nvim" })
        use({
            "lewis6991/impatient.nvim",
            -- config = function()
            -- require("impatient").enable_profile()
            -- require("impatient")
            -- end,
        })
        use({
            "ellisonleao/gruvbox.nvim",
            config = req("config.appearance.themes.gruvbox"),
        })

        -- use({
        --     "sainnhe/gruvbox-material",
        --     config = req("config.appearance.themes.gruvbox"),
        -- })
        use({ "stevearc/dressing.nvim", config = req("config.appearance.dressing") })
        use({
            "rcarriga/nvim-notify",
            config = function()
                require("core.notify")
                vim.notify = require("notify")
            end,
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
            "folke/tokyonight.nvim",
            branch = "main",
            -- config = req("config.appearance.themes.tokyonight"),
        })
        use({ "catppuccin/nvim", as = "catppuccin", config = req("config.appearance.themes.catppuccin") })

        -- set theme
        vim.cmd("colorscheme " .. current_theme)

        use({
            "norcalli/nvim-colorizer.lua",
            config = function()
                require("colorizer").setup()
            end,
        })

        use({
            "nvim-lualine/lualine.nvim",
            requires = { "kyazdani42/nvim-web-devicons", opt = true },
            config = req("config.appearance.lualine"),
        })

        use("williamboman/mason.nvim")
        use({ "williamboman/mason-lspconfig.nvim" })
        use({
            "neovim/nvim-lspconfig",
            config = req("lsp.lsp"),
            -- to auto install the ones I use
            -- "WhoIsSethDaniel/mason-tool-installer.nvim",
        })

        use("simrat39/rust-tools.nvim")
        use({
            "nvim-treesitter/nvim-treesitter",
            run = ":TSUpdate",
            config = req("core.treesitter"),
        })

        use("nvim-treesitter/nvim-treesitter-context")
        use({
            "glepnir/lspsaga.nvim",
            branch = "main",
            config = req("lsp.lspsaga"),
        })

        -- convert to luasnip using
        -- - https://github.com/smjonas/snippet-converter.nvim
        -- and
        -- - https://cj.rs/blog/ultisnips-to-luasnip/

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
        -- TODO: remove this dependency
        -- nvim-cmp depends on dap
        use({
            "hrsh7th/nvim-cmp",
            requires = {
                "nvim-lua/plenary.nvim",
                "onsails/lspkind-nvim",
                "hrsh7th/cmp-nvim-lsp",
                { "hrsh7th/cmp-nvim-lua", ft = "lua" },
                "hrsh7th/cmp-path",
                "hrsh7th/cmp-buffer",
                "hrsh7th/cmp-cmdline",
                "petertriho/cmp-git",
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

        use("jayp0521/mason-null-ls.nvim")

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
        })

        -- TODO: remove this
        -- use({
        --     "kyazdani42/nvim-tree.lua",
        --     requires = { "kyazdani42/nvim-web-devicons", opt = true }, -- optional, for file icons
        --     config = req("core.nvim-tree"),
        --     cmd = { "NvimTreeToggle", "NvimTreeOpen" },
        -- })

        use({
            "ThePrimeagen/harpoon",
            requires = { "nvim-lua/plenary.nvim" },
            config = req("core.harpoon"),
            module = "harpoon",
        })

        -- TODO: delete this
        -- use({
        --     "phaazon/hop.nvim",
        --     branch = "v1", -- optional but strongly recommended
        --     config = function()
        --         require("hop").setup({ keys = "etovxqpdygfblzhckisuran" })
        --     end,
        --     cmd = { "HopChar1" },
        -- })

        use({
            "mfussenegger/nvim-dap",
            requires = {
                -- { "Pocco81/DAPInstall.nvim", module = "dap-install" },
                { "rcarriga/nvim-dap-ui", module = "dapui" },
                { "theHamsta/nvim-dap-virtual-text", module = "nvim-dap-virtual-text" },
                { "nvim-telescope/telescope-dap.nvim" },
                { "rcarriga/cmp-dap" },
                { "mfussenegger/nvim-dap-python" },
                { "leoluz/nvim-dap-go" },
            },
            -- module = "dap",
            config = req("lsp.dap.dap"),
            module = "dap",
        })

        use("jayp0521/mason-nvim-dap.nvim")

        use({
            "jbyuki/one-small-step-for-vimkind",
            requires = { "mfussenegger/nvim-dap", module = "dap" },
            module = "osv",
        }) -- debug lua files

        use({
            "github/copilot.vim",
            config = function()
                vim.g.copilot_filetypes = { ["*"] = false, js = true, jsx = true, python = true }
            end,
            -- cmd = "Copilot",
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
        use("nvim-treesitter/nvim-treesitter-textobjects")
        -- use({
        --     -- https://github.com/nvim-treesitter/nvim-treesitter-textobjects
        --     "nvim-treesitter/nvim-treesitter-textobjects",
        --     requires = { "nvim-treesitter/nvim-treesitter" },
        --     config = req("core.nvim-treesitter-textobjects"),
        -- })

        -- meh
        use({
            "preservim/vim-markdown",
            requires = "godlygeek/tabular",
        })
        --

        use({
            "folke/which-key.nvim",
            config = req("config.appearance.whichkey"),
        })
        -- use({
        --     "yggdroot/indentLine",
        --     config = function()
        --         vim.g.indentLine_char = "┆"
        --         vim.g.indentLine_enabled = 0
        --         -- show double quotes in json
        --         -- vim.o.concealLevel = 0
        --     end,
        -- })
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

        use({
            "preservim/tagbar",
            config = function()
                vim.g.tagbar_map_closefold = "zc"
                vim.g.tagbar_map_openfold = "zo"
                vim.g.tagbar_show_linenumbers = 2
            end,
            cmd = { "TagbarToggle" },
        })
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

        -- TODO: change to smolovk/projector.nvim
        use({
            "tpope/vim-projectionist",
            requires = "neovim/nvim-lspconfig",
            config = req("core.projectionist"),
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

        use({
            "kristijanhusak/vim-dadbod-ui",
            requires = { "tpope/vim-dadbod", "tpope/vim-dotenv", "kristijanhusak/vim-dadbod-completion" },
            config = req("core.dadbod"),
            cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer", "DBUILastQueryInfo" },
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
        })

        use("bkad/CamelCaseMotion")
        use("gpanders/editorconfig.nvim")
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
        -- use({
        -- 	"vim-test/vim-test",
        -- config = req("core.vim-test"),
        -- cmd = {
        -- "TestNearest",
        -- "TestFile",
        -- "TestSuite",
        -- "TestVisit",
        -- 	},
        -- })
        use({
            "nvim-neotest/neotest",
            requires = {
                "nvim-lua/plenary.nvim",
                "nvim-treesitter/nvim-treesitter",
                "antoinemadec/FixCursorHold.nvim",
                -- "nvim-neotest/neotest-python", -- doesn't let me choose the pytest binary,
                "vim-test/vim-test",
                "nvim-neotest/neotest-vim-test",
            },
            config = req("core.neotest"),
            module = "neotest",
        })
        use({ "brooth/far.vim", cmd = { "Far", "Fardo", "Farr" } })

        use({
            "ThePrimeagen/refactoring.nvim",
            requires = {
                { "nvim-lua/plenary.nvim" },
                { "nvim-treesitter/nvim-treesitter" },
            },
            config = req("core.refactoring"),
            module = "refactoring",
        })

        -- TODO: migrate to this?
        -- use({ "michaelb/sniprun", run = "bash ./install.sh", config = req("core.sniprun"), cmd = "SnipRun" })

        --  https://github.com/pwntester/octo.nvim
        use({
            "pwntester/octo.nvim",
            requires = {
                "nvim-lua/plenary.nvim",
                "nvim-telescope/telescope.nvim",
                "kyazdani42/nvim-web-devicons",
            },
            config = function()
                require("octo").setup({ default_remote = { "origin", "upstream" } })
            end,
        })

        use({ "Vimjas/vim-python-pep8-indent" }) -- for indentation, treesitter not functional yet 23/01/2022
        use({
            -- this is what you can do
            -- https://nvim-orgmode.github.io/demo.html
            "nvim-orgmode/orgmode",
            config = req("core.org"),
        })

        -- enable when dadbod completion stops working
        -- use("nanotee/sqls.nvim")

        -- overseer tutorial, (save tasks, watch tasks etc)
        -- https://www.youtube.com/watch?v=aq3mU_Oqd6Q
        use({
            "stevearc/overseer.nvim",
            config = req("core.overseer"),
            requires = {
                "stevearc/dressing.nvim",
                "nvim-telescope/telescope.nvim",
                "rcarriga/nvim-notify",
            },
            cmd = { "OverseerRun", "OverseerRunCmd", "OverseerToggle", "OverseerQuickAction" },
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
        -- use("dracula/vim")
        use("crusoexia/vim-monokai")
        use("rebelot/kanagawa.nvim")
        use({
            "folke/todo-comments.nvim",
            requires = "nvim-lua/plenary.nvim",
            config = function()
                require("todo-comments").setup({
                    -- your configuration comes here
                    -- or leave it empty to use the default settings
                    -- refer to the configuration section below
                })
            end,
        })
        use({
            "kylechui/nvim-surround",
            tag = "*", -- Use for stability; omit to use `main` branch for the latest features
            after = { "nvim-treesitter" },
            config = req("core.nvim-surround"),
        })

        -- https://github.com/anuvyklack/hydra.nvim/wiki/Windows-and-buffers-management
        -- needs a lot of other plugins so big no no
        -- use({ "anuvyklack/hydra.nvim", config = req("core.hydra") })
        -- prettier lsp
        if vim.fn.getenv("WORKENV") == vim.NIL then
            use({
                "https://git.sr.ht/~whynothugo/lsp_lines.nvim",
                config = function()
                    local lsp_lines = require("lsp_lines")
                    lsp_lines.setup()
                    vim.diagnostic.config({ virtual_lines = false })
                    local toggle = function()
                        lsp_lines.toggle()
                        if vim.diagnostic.config()["virtual_text"] then
                            vim.diagnostic.config({ virtual_text = false })
                        else
                            vim.diagnostic.config({ virtual_text = { spacing = 2 } })
                        end
                    end
                    vim.keymap.set("", "gO", toggle, { desc = "Toggle lsp_lines" })
                end,
            })
        end

        -- TODO: test this
        -- use("smolovk/projector.nvim")
        -- TODO: test this to have custom themes per project
        -- https://muniftanjim.dev/blog/neovim-project-local-config-with-exrc-nvim/
        -- use("MunifTanjim/exrc.nvim")
        use({
            "phaazon/mind.nvim",
            config = function()
                require("mind").setup()
            end,
        })
        use({
            "lukas-reineke/indent-blankline.nvim",
            config = function()
                vim.g.indentLine_char = "┆"
                vim.g.indent_blankline_enabled = true
                vim.g.indent_blankline_filetype = { "lua", "javascript", "typescript" }
                require("indent_blankline").setup({
                    -- for example, context is off by default, use this to turn it on
                    show_current_context = true,
                    show_current_context_start = false,
                })
            end,
        })

        use({
            "akinsho/toggleterm.nvim",
            tag = "v2.*",
            config = function()
                require("toggleterm").setup()
            end,
            cmd = "ToggleTerm",
        })
        -- install without yarn or npm
        use({
            "iamcco/markdown-preview.nvim",
            run = function()
                vim.fn["mkdp#util#install"]()
            end,
        })
        use({
            "rest-nvim/rest.nvim",
            branch = "main",
            requires = "nvim-lua/plenary.nvim",
            config = req("core.rest"),
        })

        -- https://github.com/nvim-telescope/telescope-media-files.nvim
        -- for better go experience
        -- https://github.com/ray-x/go.nvim
        -- this is for faster startup!
        use("navarasu/onedark.nvim")
    end,
    config = {
        display = {
            open_fn = function()
                return require("packer.util").float({ border = "single" })
            end,
        },
    },
})
