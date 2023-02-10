vim.opt.termguicolors = true
local function req(module)
    return function(name, opts)
        require(module)
    end
    -- return string.format('require("%s")', module)
end

vim.g.mapleader = t("<Space>")
vim.g.maplocalleader = "\\"

return {
    "lewis6991/impatient.nvim",
    {
        "ellisonleao/gruvbox.nvim",
        lazy = false,
        config = req("config.appearance.themes.gruvbox"),
    },

    {
        "stevearc/dressing.nvim",
        config = req("config.appearance.dressing"),
    },
    {
        "rcarriga/nvim-notify",
        config = function()
            require("core.notify")
            vim.notify = require("notify")
        end,
    },
    {
        "nvim-telescope/telescope.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
        },
        config = req("core.telescope"),
    },
    {
        "folke/tokyonight.nvim",
        branch = "main",
        -- config = req("config.appearance.themes.tokyonight"),
    },
    { "catppuccin/nvim", config = req("config.appearance.themes.catppuccin") },

    "norcalli/nvim-colorizer.lua",

    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "kyazdani42/nvim-web-devicons", opt = true },
        config = req("config.appearance.lualine"),
    },

    {
        "neovim/nvim-lspconfig",
        config = req("lsp.lsp"),
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            -- Useful status updates for LSP
        },
    },

    "simrat39/rust-tools.nvim",
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = req("core.treesitter"),
    },

    {
        "nvim-treesitter/nvim-treesitter-context",
        config = function()
            vim.cmd("hi TreesitterContextLineNumber gui=bold guifg=orange")
        end,
    },
    {
        "glepnir/lspsaga.nvim",
        branch = "main",
        config = req("lsp.lspsaga"),
    },

    -- convert to luasnip using
    -- - https://github.com/smjonas/snippet-converter.nvim
    -- and
    -- - https://cj.rs/blog/ultisnips-to-luasnip/

    {
        "SirVer/ultisnips",
        init = function()
            vim.g.UltiSnipsNoMap = true
            vim.g.UltiSnipsExpandTrigger = "<a-s>"
            vim.g.UltiSnipsJumpForwardTrigger = "<a-k>"
            vim.g.UltiSnipsJumpBackwardTrigger = "<a-K>"
            -- vim.g.UltiSnipsListSnippets = "<c-tab>"
            vim.g.UltiSnipsSnippetDirectories = { "my_snippets", "UltiSnips" }
        end,
        config = function()
            require("cmp_nvim_ultisnips.mappings")
        end,
        dependencies = "quangnguyen30192/cmp-nvim-ultisnips",
    },
    "honza/vim-snippets",
    {
        "ray-x/lsp_signature.nvim",
        config = req("lsp.lsp-signature"),
    },
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
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
    },

    {
        "jose-elias-alvarez/null-ls.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = req("lsp.formatters"),
    },

    "jayp0521/mason-null-ls.nvim",

    {
        "nvim-treesitter/playground",
        dependencies = "nvim-treesitter/nvim-treesitter",
        cmd = { "TSPlaygroundToggle", "TSHighlightCapturesUnderCursor" },
    },
    {
        "ahmedkhalf/project.nvim",
        dependencies = "nvim-telescope/telescope.nvim",
        config = req("lsp.project"),
    },
    {
        "numToStr/Comment.nvim",
        config = req("core.comment"),
    },
    --
    -- -- Lazy loading:
    -- -- Load on specific commands
    {
        "tpope/vim-dispatch",
    },

    {
        "ThePrimeagen/harpoon",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = req("core.harpoon"),
        module = "harpoon",
    },

    {
        "mfussenegger/nvim-dap",
        dependencies = {
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
    },

    "jayp0521/mason-nvim-dap.nvim",

    {
        "jbyuki/one-small-step-for-vimkind",
        dependencies = { "mfussenegger/nvim-dap", module = "dap" },
        module = "osv",
    }, -- debug lua files

    {
        "github/copilot.vim",
        init = function()
            vim.g.copilot_filetypes = { ["*"] = false, js = true, jsx = true, python = true }
        end,
        -- cmd = "Copilot",
    },

    -- breaking nvim-surround, should look for better option using nvim-treesitter
    {
        "wellle/targets.vim",
        init = function()
            vim.g.targets_aiAI = { "a", "l", "A", "L" }
            vim.g.targets_mapped_aiAI = { "a", "i", "A", "I" }
            vim.g.targets_nl = { "n", "N" }
            -- this script lets you apply macros to multiple lines
            -- vim.cmd("source ~/.config/nvim/modules/visual-at.vim")
        end,
    },
    "tpope/vim-surround",
    "tpope/vim-repeat",
    "tommcdo/vim-exchange",
    {
        "preservim/vim-markdown",
        dependencies = { "godlygeek/tabular" },
    },

    {
        "folke/which-key.nvim",
        config = req("config.appearance.whichkey"),
    },
    {
        "Pocco81/TrueZen.nvim",
        config = req("core.truezen"),
        cmd = { "TZMinimalist", "TZFocus", "TZAtaraxis" },
    },

    {
        "mbbill/undotree",
        cmd = { "UndotreeToggle" },
    },

    {
        "preservim/tagbar",
        init = function()
            vim.g.tagbar_map_closefold = "zc"
            vim.g.tagbar_map_openfold = "zo"
            vim.g.tagbar_show_linenumbers = 2
        end,
        cmd = { "TagbarToggle" },
    },
    -- --------------------
    {
        "mattn/emmet-vim",
        init = function()
            vim.g.user_emmet_install_global = 0
        end,
        ft = { "html", "js", "ts", "css", "vue", "svelte", "jsx", "tsx" },
    },
    {
        "alvan/vim-closetag",
        config = req("core.closetags"),
        ft = { "html", "js", "ts", "css", "vue", "svelte", "jsx", "tsx" },
    },

    {
        "windwp/nvim-autopairs",
        config = req("core.autopairs"),
    },

    {
        "tpope/vim-projectionist",
        dependencies = { "neovim/nvim-lspconfig" },
        config = req("core.projectionist"),
    },

    -- check if there is a file .env
    {
        "tpope/vim-dotenv",
        dependencies = "neovim/nvim-lspconfig",
        cond = function()
            return require("lspconfig.util").root_pattern(".env*")(vim.fn.getcwd()) ~= nil
        end,
    },

    {
        "kristijanhusak/vim-dadbod-ui",
        dependencies = { "tpope/vim-dadbod", "tpope/vim-dotenv", "kristijanhusak/vim-dadbod-completion" },
        config = req("core.dadbod"),
        cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer", "DBUILastQueryInfo" },
    },
    -- fun
    { "ThePrimeagen/vim-apm", cmd = { "VimApm" } },
    {
        "ThePrimeagen/vim-be-good",
        cmd = { "VimBeGood" },
    },
    {
        "ThePrimeagen/git-worktree.nvim",
    },

    {
        "lewis6991/gitsigns.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = req("core.gitsigns"),
    },

    "bkad/CamelCaseMotion",
    "gpanders/editorconfig.nvim",
    { "bps/vim-textobj-python", ft = "python" },

    {
        "AndrewRadev/splitjoin.vim",
        init = function()
            vim.g.splitjoin_split_mapping = "gs"
            vim.g.splitjoin_join_mapping = "gS"
        end,
    },
    {
        "matze/vim-move",
        init = function()
            vim.g.move_key_modifier = "C"
            vim.g.move_map_keys = 0
        end,
    },

    {
        "szw/vim-maximizer",
        cmd = "MaximizerToggle",
        init = function()
            vim.g.maximizer_set_default_mapping = 0
        end,
    },

    -- :h vis commands for visual selection
    "vim-scripts/vis",

    { "osyo-manga/vim-brightest", cmd = "BrightestToggle" },

    { "junegunn/gv.vim", cmd = "GV" },

    {
        "rbgrouleff/bclose.vim",
        cmd = "Bclose",
        init = function()
            --The :Bclose command deletes a buffer without changing the window layout, unlike :bd.
            vim.g.bclose_no_plugin_maps = 1
        end,
    },

    {
        "frazrepo/vim-rainbow",
        cmd = "RainbowToggle",
        init = function()
            vim.g.rainbow_active = 0
        end,
    },

    {
        "tpope/vim-fugitive",
        dependencies = "tpope/vim-rhubarb",
        config = function()
            vim.opt.diffopt = "internal,vertical,closeoff,filler"
        end,
    },
    -- {
    --     "tpope/vim-obsession",
    --     cmd = { "Obsession", "Obsession!" },
    --     config = function()
    --         vim.g.obsession_no_bufenter = 1
    --         vim.opt.statusline = "%{ObsessionStatus()}"
    --     end,
    -- },
    {
        "nvim-neotest/neotest",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-treesitter/nvim-treesitter",
            "antoinemadec/FixCursorHold.nvim",
            -- "nvim-neotest/neotest-python", -- doesn't let me choose the pytest binary,
            "vim-test/vim-test",
            "nvim-neotest/neotest-vim-test",
        },
        config = req("core.neotest"),
        module = "neotest",
    },
    { "brooth/far.vim", cmd = { "Far", "Fardo", "Farr" } },

    {
        "ThePrimeagen/refactoring.nvim",
        dependencies = {
            { "nvim-lua/plenary.nvim" },
            { "nvim-treesitter/nvim-treesitter" },
        },
        config = req("core.refactoring"),
        module = "refactoring",
    },

    {
        "pwntester/octo.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope.nvim",
            "kyazdani42/nvim-web-devicons",
        },
        opts = { default_remote = { "origin", "upstream" } },
    },

    { "Vimjas/vim-python-pep8-indent" }, -- for indentation, treesitter not functional yet 23/01/202,
    {
        -- this is what you can do
        -- https://nvim-orgmode.github.io/demo.html
        "nvim-orgmode/orgmode",
        config = req("core.org"),
    },

    -- colors
    -- use("dracula/vim")
    "crusoexia/vim-monokai",
    "rebelot/kanagawa.nvim",
    {
        "folke/todo-comments.nvim",
        config = function()
            require("todo-comments").setup({})
        end,
        dependencies = "nvim-lua/plenary.nvim",
    },

    -- use({ "anuvyklack/hydra.nvim", config = req("core.hydra") })
    -- prettier lsp
    {
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
    },

    -- TODO: test this
    -- use("smolovk/projector.nvim")

    -- TODO: test this to have custom themes per project
    -- https://muniftanjim.dev/blog/neovim-project-local-config-with-exrc-nvim/
    -- use("MunifTanjim/exrc.nvim")
    "phaazon/mind.nvim",
    {
        "lukas-reineke/indent-blankline.nvim",
        init = function()
            vim.g.indentLine_char = "┆"
            vim.g.indent_blankline_enabled = true
            vim.g.indent_blankline_filetype = { "lua", "javascript", "typescript" }
            local M = require("utils.lua.highlight")
            M.highlight("IndentBlanklineIndent1", { fg = M.colors.dark_red, gui = "nocombine" })
            M.highlight("IndentBlanklineIndent2", { fg = M.colors.dark_yellow, gui = "nocombine" })
            M.highlight("IndentBlanklineIndent3", { fg = M.colors.dimm_green, gui = "nocombine" })
            M.highlight("IndentBlanklineIndent4", { fg = M.colors.dimm_purple, gui = "nocombine" })
            M.highlight("IndentBlanklineIndent5", { fg = M.colors.white, gui = "nocombine" })
            M.highlight("IndentBlanklineIndent6", { fg = M.colors.bracket_grey, gui = "nocombine" })
            M.highlight("IndentBlanklineContextChar", { fg = M.colors.visual_grey, gui = "nocombine" })
            M.highlight("IndentBlanklineContextStart", { sp = M.colors.dimm_black, gui = "underline" })
            M.highlight("IndentBlanklineContextSpaceChar", { gui = "nocombine" })
        end,
        opts = {
            show_end_of_line = true,
            space_char_blankline = " ",
            show_current_context = true,
            show_current_context_start = false,
            char_highlight_list = {
                "IndentBlanklineIndent1",
                "IndentBlanklineIndent2",
                "IndentBlanklineIndent3",
                "IndentBlanklineIndent4",
                "IndentBlanklineIndent5",
                "IndentBlanklineIndent6",
            },
        },
    },

    {
        "akinsho/toggleterm.nvim",
        config = function()
            require("toggleterm").setup()
        end,
        cmd = "ToggleTerm",
    },
    {
        "iamcco/markdown-preview.nvim",
        build = function()
            vim.fn["mkdp#util#install"]()
        end,
    },
    {
        "rest-nvim/rest.nvim",
        -- dev = true,
        branch = "main",
        dependencies = "nvim-lua/plenary.nvim",
        config = req("core.rest"),
    },

    -- https://github.com/nvim-telescope/telescope-media-files.nvim
    -- for better go experience
    -- https://github.com/ray-x/go.nvim
    -- this is for faster startup!
    "navarasu/onedark.nvim",
    {
        "tjdevries/sg.nvim",
        dependencies = "nvim-lua/plenary.nvim",
        -- config = function()
        --     require("sg").setup({
        --         -- Pass your own custom attach function
        --         --    If you do not pass your own attach function, then the following maps are provide:
        --         --        - gd -> goto definition
        --         --        - gr -> goto references
        --         -- on_attach = your_custom_lsp_attach_function,
        --     })
        -- end,
        build = "cargo build --workspace",
    },

    "kana/vim-textobj-user",
    {
        "glts/vim-textobj-comment",
        dependencies = "kana/vim-textobj-user",
        init = function()
            vim.g.textobj_comment_no_default_key_mappings = 1
        end,
    },
    {
        "kana/vim-textobj-line",
        dependencies = "kana/vim-textobj-user",
        init = function()
            vim.g.textobj_line_no_default_key_mappings = 1
        end,
    },

    {
        "kana/vim-textobj-entire",
        dependencies = "kana/vim-textobj-user",
        init = function()
            vim.g.textobj_entire_no_default_key_mappings = 1
        end,
    },

    {
        "nvim-treesitter/nvim-treesitter-textobjects",
        dependencies = { "nvim-treesitter/nvim-treesitter", "kana/vim-textobj-user" },
    },

    -- enable when dadbod completion stops working
    -- use("nanotee/sqls.nvim")

    -- use({
    --     "stevearc/overseer.nvim",
    --     config = req("core.overseer"),
    --     dependencies = {
    --         "stevearc/dressing.nvim",
    --         "nvim-telescope/telescope.nvim",
    --         "rcarriga/nvim-notify",
    --     },
    --     cmd = { "Overseerbuild", "OverseerbuildCmd", "OverseerToggle", "OverseerQuickAction" },
    -- })

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
}
