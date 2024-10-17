local setup = {}

local config = function()
  local previewers = require("telescope.previewers")
  local Job = require("plenary.job")
  -- for ignoring binarys in preview
  local new_preview_maker = function(filepath, bufnr, opts)
    if vim.fn.has("win32") == 1 then
      return
    end
    filepath = vim.fn.expand(filepath)
    Job:new({
      command = "file",
      args = { "--mime-type", "-b", filepath },
      on_exit = function(j)
        local mime_type = vim.split(j:result()[1], "/")[1]
        if mime_type == "text" then
          previewers.buffer_previewer_maker(filepath, bufnr, opts)
        else
          -- maybe we want to write something to the buffer here
          vim.schedule(function()
            vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "BINARY" })
          end)
        end
      end,
    }):sync()
  end

  -- local find_command = function()
  -- 	-- if it finds fd use it else let telescope choose
  -- 	if 1 == vim.fn.executable("fd") then
  -- 		return {
  -- 			find_command = { "fd", "--type", "f", "--strip-cwd-prefix" },
  -- 		}
  -- 	else
  -- 		return {}
  -- 	end
  -- end
  local actions = require("telescope.actions")
  local actions_layout = require("telescope.actions.layout")

  local mappings = {
    i = {
      ["<esc>"] = actions.close,
      ["<a-'>"] = function()
        vim.cmd("stopinsert")
      end,
      ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse, --select
      ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
      ["<a-p>"] = actions_layout.toggle_preview,
      ["<c-s>"] = actions.select_horizontal,
      ["<c-v>"] = actions.select_vertical,
      ["?"] = actions.which_key,

      ["<a-n>"] = actions.move_selection_next,
      ["<a-e>"] = actions.move_selection_previous,

      ["<a-s-u>"] = actions.cycle_history_next,
      ["<a-s-d>"] = actions.cycle_history_prev,

      ["<c-e>"] = actions.preview_scrolling_up,
      ["<c-n>"] = actions.preview_scrolling_down,

      ["<a-d>"] = function(prompt_bufnr)
        for _ = 1, 2, 1 do
          actions.move_selection_next(prompt_bufnr)
        end
      end,
      ["<a-u>"] = function(prompt_bufnr)
        for _ = 1, 2, 1 do
          actions.move_selection_previous(prompt_bufnr)
        end
      end,

      ["<a-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
      ["<a-s-q>"] = actions.smart_add_to_qflist + actions.open_qflist,
      ["<a-l>"] = actions.smart_send_to_loclist + actions.open_loclist,
      ["<a-s-l>"] = actions.smart_add_to_loclist + actions.open_loclist,
    },
    n = {
      ["<esc>"] = actions.close,
      ["<a-p>"] = actions_layout.toggle_preview,

      ["n"] = actions.move_selection_next,
      ["e"] = actions.move_selection_previous,

      ["d"] = function(prompt_bufnr)
        for _ = 1, 2, 1 do
          actions.move_selection_next(prompt_bufnr)
        end
      end,
      ["u"] = function(prompt_bufnr)
        for _ = 1, 2, 1 do
          actions.move_selection_previous(prompt_bufnr)
        end
      end,

      ["H"] = actions.move_to_top,
      ["M"] = actions.move_to_middle,
      ["L"] = actions.move_to_bottom,
      ["gg"] = actions.move_to_top,
      ["G"] = actions.move_to_bottom,
      ["<a-'>"] = function()
        vim.cmd("stopinsert")
      end,
      ["?"] = actions.which_key,
    },
  }
  local vimgrep_arguments = {
    "rg",
    "-uu",
    "-L",
    "--color=never",
    "--no-heading",
    "--with-filename",
    "--line-number",
    "--column",
    "--smart-case",
    "--trim",
  }

  setup = {
    pickers = {
      -- find_files = find_command(),
      find_files = {
        follow = true,
      },
      buffers = {
        theme = "cursor", -- ivy, dropdown, cursor
        layout_config = { width = 0.7 },
      },
      live_grep = {
        theme = "ivy",     -- ivy, dropdown, cursor
        only_sort_text = true, -- this is so it matches on filepath too
        -- layout_config = { width = 0.7 }
      },
      grep_string = {
        theme = "ivy", -- ivy, dropdown, cursor
      },
    },
    defaults = {
      layout_strategy = "horizontal", -- center, horizontal, cursor, vertical, flex, bottom_pane
      layout_config = { width = 0.7 },
      mappings = mappings,
      -- Example: { "^scratch/" } -- ignore all files in scratch directory
      -- Example: { "%.npz" } -- ignore all npz files
      file_ignore_patterns = { "^vendor/" }, -- or just add it to the ~/.ignore file, doesn't work for git files
      -- file_ignore_patterns = { "node_modules" }, -- or just add it to the ~/.ignore file
      buffer_previewer_maker = new_preview_maker,
      -- rg is needed for live_grep to work
      vimgrep_arguments = vimgrep_arguments,
    },
    extensions = {
      --defaults
      -- fzf = {
      --   fuzzy = true,                   -- false will only do exact matching
      --   override_generic_sorter = true, -- override the generic sorter
      --   override_file_sorter = true,    -- override the file sorter
      --   case_mode = "smart_case",       -- or "ignore_case" or "respect_case"
      --   -- the default case_mode is "smart_case"
      -- },
    },
    -- other configuration values here
  }
end

return {
  "nvim-telescope/telescope.nvim",
  version = "*",
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
    },
  },
  config = function()
    config()
    require("telescope").setup(setup)
    if vim.fn.executable("fzf") and vim.loop.os_uname().sysname == "Linux" then
      require("telescope").load_extension("fzf")
    end
  end,
}
