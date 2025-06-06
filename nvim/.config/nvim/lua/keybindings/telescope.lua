local M = {}
local s = { silent = true }
local nor = { noremap = true }
local nor_s = vim.tbl_extend("keep", nor, s)
local map = vim.keymap.set

local desc = function(desc)
  return vim.tbl_extend("keep", nor_s, { desc = desc })
end
function custom_find_files()
  -- doing this because of bug where if you open a monorepo and then go a folder up, use
  -- telescope and then go back to prev folder and do telescope, it will show contents of pwd
  -- and not current dir
  if vim.bo.filetype == "netrw" then
    require("telescope.builtin").find_files({
      cwd = vim.b.netrw_curdir,
      follow = true,
      hidden = true,
      no_ignore = false, -- ignore .gitignore
      sort_last_used = true,
    })
    return
  end

  require("telescope.builtin").find_files({
    cwd = vim.fn.expand("%:p:h"),
    follow = true,
    hidden = true,
    no_ignore = false, -- ignore .gitignore
    sort_last_used = true,
  })
end

M.load_mappings = function()
  map("n", "<c-p>", custom_find_files, nor_s)

  map("n", "<c-g>", function()
    require("utils.lua.telescope").git_files_or_curdir_parent({
      hidden = true,
      no_ignore = true,
    })
  end, nor_s)

  -- cmd("autocmd FileType TelescopePrompt let b:autopairs_enabled = 0")
  -- vim.api.nvim_create_autocmd("TelescopePrompt", {
  --   callback = function()
  --     map("i", "<c-s-u>", "")
  --   end
  -- })

  map("n", "<a-r>", function()
    if vim.bo.filetype ~= "netrw" then
      require("telescope.builtin").live_grep({ cwd = vim.fn.expand("%:p:h"), hidden = true, additional_args = { '--multiline' } })
    else
      require("telescope.builtin").live_grep({ cwd = vim.b.netrw_curdir, hidden = true, additional_args = { '--multiline' } })
    end
  end, nor_s)

  map("n", "<a-s-r>", function()
    local cwd = require("utils.lua.telescope").git_root_or_curdir_parent()
    -- __AUTO_GENERATED_PRINT_VAR_START__
    print([==[M.load_mappings#(anon) cwd:]==], vim.inspect(cwd)) -- __AUTO_GENERATED_PRINT_VAR_END__
    require("telescope.builtin").live_grep({ cwd = cwd, hidden = true, no_ignore = true, no_ignore_parent = true })
  end, nor_s)

  map(
    "n",
    "<a-c-r>",
    ":lua require('telescope.builtin').grep_string({path_display = { 'smart' }, only_sort_text = true, word_match = '-w', search = '',})<cr>",
    desc("Telescope fuzzy")
  )

  -- word under cursor
  map("n", "<a-w>", function()
    require("telescope.builtin").grep_string({
      path_display = { "smart" },
      only_sort_text = true,
      word_match = "-w",
      search = vim.fn.expand("<cword>"),
    })
  end, desc("Telescope fuzzy"))
  map(
    "n",
    "<a-b>",
    ':lua require("telescope.builtin").buffers(require("telescope.themes").get_dropdown({cwd_only=false}))<cr>',
    nor_s
  )
  map("n", "sz", ':lua require("utils.lua.telescope").zenmode()<cr>', nor_s)

  -- t misc
  map("n", "<leader>Tj", ':lua require("telescope.builtin").jumplist()<cr>', desc("builtin.jumplist"))
  map("n", "<leader>TL", ':lua require("telescope.builtin").loclist()<cr>', desc("builtin.loclist"))
  map("n", "<leader>Tq", ':lua require("telescope.builtin").quickfix()<cr>', desc("builtin.quickfix"))
  map("n", "<leader>Tr", ':lua require("telescope.builtin").registers()<cr>', desc("builtin.registers"))
  map("n", "<leader>Ta", ':lua require("telescope.builtin").autocommands()<cr>', desc("builtin.autocommands"))
  map("n", "<leader>Tk", ':lua require("telescope.builtin").keymaps()<cr>', desc("builtin.keymaps"))
  map("n", "<leader>TM", ':lua require("telescope.builtin").marks()<cr>', desc("builtin.marks"))
  map("n", "<leader>Tm", ':lua require("telescope.builtin").man_pages()<cr>', desc("builtin.man_pages"))
  map("n", "<leader>Th", ':lua require("telescope.builtin").help_tags()<cr>', desc("builtin.help_tags"))
  map("n", "<leader>TH", ':lua require("telescope.builtin").highlights()<cr>', desc("builtin.highlights"))
  map("n", "<leader>Tvo", ':lua require("telescope.builtin").vim_options()<cr>', desc("builtin.vim_options"))
  map("n", "<leader>Tvc", ':lua require("telescope.builtin").commands()<cr>', desc("builtin.commands"))
  map("n", "<leader>TvC", ':lua require("telescope.builtin").colorscheme()<cr>', desc("builtin.colorscheme"))
  map("n", "<leader>Tc", ':lua require("telescope.builtin").command_history()<cr>', desc("builtin.command_history"))
  map("n", "<leader>Ts", ':lua require("telescope.builtin").search_history()<cr>', desc("builtin.search_history"))
  -- custom

  -- folders
  map("n", "<leader>tb", ':lua require("utils.lua.telescope").select_bg()<cr>', nor_s)
  map("n", "<leader>tn", ':lua require("utils.lua.telescope").sort_notes()<cr>', nor_s)
  map(
    "n",
    "<leader>tn",
    ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP $NOTES>', cwd = '$NOTES', search ='',  shorten_path = true})<CR>",
    nor_s
  )

  -- map("n", "<localleader>gf", ':lua require("utils.lua.telescope").projects()<cr>', nor_s)
  -- map("n", "<localleader>gF", ':lua require("utils.lua.telescope").files()<cr>', nor_s)
  -- map("n", "<localleader>gd", ':lua require("utils.lua.telescope").dotfiles()<cr>', nor_s)

  -- map("n", "<localleader>gu", ':lua require("utils.lua.telescope").utilities()<cr>', nor_s)
  -- NOTE: you should use ,vc instead
  -- map("n", "<localleader>Vc", ':lua require("utils.lua.telescope").nvim({path = "lua/core/"})<cr>', nor_s)
  -- map("n", "<localleader>VC", ':lua require("utils.lua.telescope").nvim({path = "lua/config/"})<cr>', nor_s)
  -- map("n", "<localleader>Vu", ':lua require("utils.lua.telescope").nvim({path = "lua/utils/"})<cr>', nor_s)
  -- map("n", "<localleader>Vl", ':lua require("utils.lua.telescope").nvim({path = "lua/lsp/"})<cr>', nor_s)
  -- map("n", "<localleader>Vd", ':lua require("utils.lua.telescope").nvim({path = "lua/lsp/dap"})<cr>', nor_s)

  map("n", "<a-a>", ':lua require("utils.lua.telescope").find_folders({})<cr>', nor_s)
  map("n", "<a-A>", ':lua require("utils.lua.telescope").find_folders({git=true})<cr>', nor_s)

  -- live_grep
  -- map("n", "<localleader>gn.", ':lua require("utils.lua.telescope").notes_grep()<cr>', nor_s)
  -- map("n", "<localleader>gc.", ':lua require("utils.lua.telescope").code_grep()<cr>', nor_s)
  -- map("n", "<localleader>gpl", ':lua require("utils.lua.telescope").playground_grep()<cr>', nor_s)
  -- map("n", "<localleader>gp.", ':lua require("utils.lua.telescope").projects_grep()<cr>', nor_s)
  -- map("n", "<localleader>gwo", ':lua require("utils.lua.telescope").work_grep()<cr>', nor_s)

  -- map("n", "<localleader>Wo", ':lua require("utils.lua.telescope").notes_grep()<cr>', nor_s)

  -- deprecated 05/01/2022
  -- map('n', '<a-f>', ':lua require("telescope.builtin").file_browser()<cr>',nor_s) https://github.com/nvim-telescope/telescope-file-browser.nvim/issues/3
  map("n", "<leader>tt", ":Telescope<cr>", nor_s)
  -- t plugins
  map("n", "<leader>t,h", ":Telescope harpoon marks<cr>", nor_s)

  map("n", "<leader>t,p", ":Telescope projects<cr>", nor_s)

  map("n", "<leader>t,P", ':lua require("utils.lua.telescope").plugins_def()<cr>', nor_s)

  map("n", "<leader>t,r", ":Telescope refactoring<cr>", nor_s)

  map("n", "<leader>tdc", ":Telescope dap configurations", nor_s)
  map("n", "<leader>tdC", ":Telescope dap commands", nor_s)
  map("n", "<leader>tdl", ":Telescope dap list_breakpoints", nor_s)
  map("n", "<leader>tdv", ":Telescope dap variables", nor_s)
  map("n", "<leader>tdf", ":Telescope dap frames", nor_s)

  -- use <c-d> while in this to delete it!
  map("n", "gwc", ":Telescope git_worktree create_git_worktree<cr>", nor)
  map("n", "gww", ":Telescope git_worktree git_worktrees<cr>", nor)
  map("n", "gW", ":Telescope git_worktree git_worktrees<cr>", nor)
  map("n", "gwC", function()
    local branch = vim.fn.input("Enter branch name:")
    local path = vim.split(branch, "/")[2]
    require("git-worktree").create_worktree(path, branch, "origin")
    print("Added " .. path .. "!")
  end, desc("git worktree create with slash"))

  -- telescope lsp
  map("n", "<leader>tlr", ':lua require("telescope.builtin").lsp_references()<cr>', nor_s)
  map("n", "<leader>tls", ':lua require("telescope.builtin").lsp_document_symbols()<cr>', nor_s)
  map("n", "<leader>tlS", ':lua require("telescope.builtin").lsp_dynamic_workspace_symbols()<cr>', nor_s)
  map("n", "<leader>tla", ':lua require("telescope.builtin").lsp_code_actions()<cr>', nor_s)
  map("v", "<leader>tla", ':lua require("telescope.builtin").lsp_range_code_actions()<cr>', nor_s)
  map("n", "<leader>tlt", ':lua require("telescope.builtin").lsp_type_definitions()<cr>', nor_s)
  map("n", "<leader>tli", ':lua require("telescope.builtin").lsp_implementations()<cr>', nor_s)
  map("n", "<leader>tlD", ':lua require("telescope.builtin").lsp_definitions()<cr>', nor_s)
  map("n", "<leader>tld", ':lua require("telescope.builtin").diagnostics()<cr>', nor_s)
  map("n", "<leader>tlws", ':lua require("telescope.builtin").lsp_workspace_symbols()<cr>', nor_s)


  -- git namespace
  map("n", "<leader>gtc", ':lua require("telescope.builtin").git_commits()<cr>', nor_s)
  map("n", "<leader>gtC", ':lua require("telescope.builtin").git_bcommits()<cr>', nor_s)
  map("n", "<leader>gtb", ':lua require("telescope.builtin").git_branches()<cr>', nor_s)
  map("n", "<leader>gts", ':lua require("telescope.builtin").git_status()<cr>', nor_s)
  map("n", "<leader>gtS", ':lua require("telescope.builtin").git_stash()<cr>', nor_s)

  map("n", "<leader>tp", ":Telescope projects<cr>", nor)                                        -- recently opened projects!!
  map("n", "<c-s-s>", ":TodoTelescope<cr>", nor)                                                -- recently opened projects!!

  map("n", "<leader>tC", "<cmd>lua require('utils.lua.color_picker').choose_colors()<cr>", nor) -- recently opened porjects!!
end
return M
