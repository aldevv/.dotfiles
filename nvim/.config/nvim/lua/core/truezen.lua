require("true-zen").setup({
  modes = { -- configurations per mode
    ataraxis = {
      shade = "dark", -- if `dark` then dim the padding windows, otherwise if it's `light` it'll brighten said windows
      backdrop = 0, -- percentage by which padding windows should be dimmed/brightened. Must be a number between 0 and 1. Set to 0 to keep the same background color
      minimum_writing_area = { -- minimum size of main window
        width = 70,
        height = 44,
      },
      quit_untoggles = true, -- type :q or :qa to quit Ataraxis mode
      padding = { -- padding windows
        left = 42,
        right = 42,
        top = 0,
        bottom = 0,
      },
      callbacks = { -- run functions when opening/closing Ataraxis mode
        open_pre = nil,
        open_pos = nil,
        close_pre = nil,
        close_pos = nil,
      },
    },
  },
})

-- local true_zen = require("true-zen")
-- true_zen.setup({
-- 	ui = {
-- 		bottom = {
-- 			laststatus = 0,
-- 			ruler = false,
-- 			showmode = false,
-- 			showcmd = false,
-- 			cmdheight = 1,
-- 		},
-- 		top = {
-- 			showtabline = 0,
-- 		},
-- 		left = {
-- 			number = false,
-- 			relativenumber = false,
-- 			signcolumn = "no",
-- 		},
-- 	},
-- 	modes = {
-- 		ataraxis = {
-- 			left_padding = 32,
-- 			right_padding = 32,
-- 			top_padding = 1,
-- 			bottom_padding = 1,
-- 			ideal_writing_area_width = { 0 },
-- 			auto_padding = true,
-- 			keep_default_fold_fillchars = true,
-- 			custom_bg = { "none", "" },
-- 			bg_configuration = true,
-- 			quit = "untoggle",
-- 			ignore_floating_windows = true,
-- 			affected_higroups = {
-- 				NonText = true,
-- 				FoldColumn = true,
-- 				ColorColumn = true,
-- 				VertSplit = true,
-- 				StatusLine = true,
-- 				StatusLineNC = true,
-- 				SignColumn = true,
-- 			},
-- 		},
-- 		focus = {
-- 			margin_of_error = 5,
-- 			focus_method = "experimental",
-- 		},
-- 	},
-- 	integrations = {
-- 		vim_gitgutter = false,
-- 		galaxyline = false,
-- 		tmux = false,
-- 		gitsigns = false,
-- 		nvim_bufferline = false,
-- 		limelight = false,
-- 		twilight = false,
-- 		vim_airline = false,
-- 		vim_powerline = false,
-- 		vim_signify = false,
-- 		express_line = false,
-- 		lualine = true,
-- 		lightline = false,
-- 		feline = false,
-- 	},
-- 	misc = {
-- 		on_off_commands = false,
-- 		ui_elements_commands = false,
-- 		cursor_by_mode = false,
-- 	},
-- })
