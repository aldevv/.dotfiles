local M = {}
local t = require("telescope.builtin")
local a = require("telescope.actions")
local s = require("telescope.actions.state")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local themes = require("telescope.themes")
local conf = require("telescope.config").values
-- pickers creation guide
-- https://github.com/nvim-telescope/telescope.nvim/blob/master/developers.md#guide-to-your-first-picker

-- @finder is just a lua table
-- pickers.new(opts, {
--     prompt_title = "Find Files",
--     finder = finders.new_oneshot_job(find_command, opts),
--     previewer = conf.file_previewer(opts),
--     sorter = conf.file_sorter(opts),
--   }):find()

local function set_bg(path)
  vim.fn.system("changeWallpaperKeepBorders " .. path)
end

M.select_bg = function()
  t.find_files({
    prompt_title = "<BG>",
    cwd = "~/Pictures/Wallpapers",
    attach_mappings = function(prompt_bufnr, map)
      local function set_the_background(close)
        local content = s.get_selected_entry()
        set_bg(content.cwd .. "/" .. content.value)
        if close then
          a.close(prompt_bufnr)
        end
      end

      map("i", "<C-b>", function()
        set_the_background()
      end)

      map("i", "<CR>", function()
        set_the_background(true)
      end)
      -- allow default maps like moving selection
      return true
    end,
  })
end

local function is_git_repo()
  vim.fn.system("git rev-parse --is-inside-work-tree")
  return vim.v.shell_error == 0
end

M.git_files_or_curdir_parent = function()
  local opts = {}

  if is_git_repo() then
    t.git_files(opts)
  else
    opts = {
      prompt_title = "<CWD DIR>",
      cwd = "..",
      follow = true,
    }
    t.find_files(opts)
  end
end

-- picker, entry maker can edit the format of the input
M.zenmode = function(opts)
  opts = opts or {}

  pickers
      .new(themes.get_dropdown(opts), {
        prompt_title = "<ZEN MODE>",
        finder = finders.new_table({
          results = { "TZAtaraxis", "TZMinimalist", "TZFocus" },
        }),
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, map)
          a.select_default:replace(function()
            a.close(prompt_bufnr) -- close prompt because you pressed <cr>
            local content = s.get_selected_entry()
            vim.api.nvim_command(content.value)
          end)
          return true
        end,
      })
      :find()
end

-- folders
M.dotfiles = function()
  t.find_files({
    prompt_title = "<AL's DOTFILES>",
    cwd = "$XDG_CONFIG_HOME/",
  })
end

M.nvim = function(opts)
  local find_command = {}
  if vim.fn.executable("rg") == 1 then
    find_command = { "rg", "--ignore", "-L", "--hidden", "--files" }
  else
    find_command = { "find", "-L" }
  end
  opts = opts or { path = "" }
  t.find_files({
    prompt_title = "<AL's NVIM>",
    cwd = "~/.config/nvim/" .. opts.path,
    find_command = { "rg", "--ignore", "-L", "--hidden", "--files" },
  })
end

function enter_find_folders_git(prompt_bufnr)
  local selected = s.get_selected_entry()
  local cmd = ":e " .. selected[1]
  vim.cmd(cmd)
  a.close(prompt_bufnr)
end

M.find_folders = function(opt)
  local opt = opt or {}
  if opt.git then
    local cmd =
    "git ls-files --full-name $(git rev-parse --show-toplevel) | xargs -n 1 dirname | sort --version-sort | uniq | grep --invert-match '^.$'"
    local files = vim.fn.system(cmd)
    t = vim.split(files, "\n")

    opt.finder = finders.new_table({ results = t })
    opt.prompt_title = "<AL's Folders Git>"
    opt.sorter = conf.generic_sorter(opts)
    opt.attach_mapping = function(prompt_bufnr, map)
      map("i", "<CR>", enter_find_folders_git)
    end

    local folders_git = pickers.new(opt)
    folders_git:find()
  else
    opt.prompt_title = "<AL's Folders>"
    opt.find_command = { "fd", "-t", "d", "--hidden", "-L" }
    t.find_files(opt)
  end
end

M.scripts = function()
  t.find_files({
    prompt_title = "<AL's SCRIPTS>",
    cwd = "$SCRIPTS/",
  })
end

M.files = function()
  t.find_files({
    prompt_title = "<AL's FILES>",
    cwd = "$FILES/",
  })
end

M.utilities = function()
  t.find_files({
    prompt_title = "<AL's UTILITIES>",
    cwd = "$UTILITIES/",
  })
end

M.projects = function()
  t.find_files({
    prompt_title = "<AL's PROJECTS>",
    cwd = "$PROJECTS/",
  })
end

M.classes = function()
  t.find_files({
    prompt_title = "<AL's CLASSES>",
    cwd = "$CLASSES/",
  })
end

M.learn = function()
  t.find_files({
    prompt_title = "<AL's LEARN>",
    cwd = "$LEARN/",
  })
end

M.playground = function()
  t.find_files({
    prompt_title = "<AL's PLAYGROUND>",
    cwd = "$PLAYGROUND/",
  })
end

M.plugins_def = function()
  t.find_files({
    prompt_title = "<AL's PLUGINS>",
    cwd = "$HOME/.local/share/nvim/site/pack/",
  })
end

M.exploits = function()
  t.find_files({
    prompt_title = "<AL's EXPLOITS>",
    cwd = "$EXP/",
  })
end

-- live_grep

M.git_root_or_curdir_parent = function()
  if is_git_repo() then
    local cmd = "git rev-parse --show-toplevel"
    local res = vim.fn.system(cmd)
    return vim.split(res, "\n")[1]
  else
    return ".."
  end
end

-- M.notes_grep = function()
--   t.live_grep({
--     prompt_title = "<GREP AL's NOTES>",
--     cwd = "$NOTES/",
--   })
-- end

M.projects_grep = function()
  t.live_grep({
    prompt_title = "<GREP AL's PROJECTS>",
    cwd = "$PROJECTS/",
  })
end

local reverseList = function(inputList)
  local reversedList = {}
  for i = #inputList, 1, -1 do
    table.insert(reversedList, inputList[i])
  end
  return reversedList
end

local show_from_notes = function(inputString)
  local targetSubstring = "notes"
  local startIndex = string.find(inputString, targetSubstring)

  if startIndex then
    return string.sub(inputString, startIndex + #targetSubstring)
  end
  return ""
end

M.sort_notes = function()
  local curfilepath = vim.fn.expand("%:p:h")
  local startIndex = string.find(curfilepath, "notes")
  if not startIndex then
    curfilepath = os.getenv("NOTES") .. "/work/mega"
  end

  -- for netrw cases
  if startIndex and vim.bo.filetype == "netrw" then
    curfilepath = vim.b.netrw_curdir
  end

  local notes = vim.split(vim.fn.system({ "sortnotes", curfilepath }), "\n")
  table.remove(notes) -- remove last item which is empty
  notes = reverseList(notes)
  for i, v in ipairs(notes) do
    notes[i] = curfilepath .. "/" .. v
  end


  local picker = pickers:new({
    prompt_title = "<SORTNOTES>",
    finder = finders.new_table({
      results = notes,
      entry_maker = function(line)
        local notes_substring = show_from_notes(line)
        return {
          value = line,
          display = notes_substring,
          ordinal = notes_substring,
        }
      end
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      a.select_default:replace(function()
        a.close(prompt_bufnr) -- close prompt because you pressed <cr>
        local content = s.get_selected_entry()
        vim.cmd("e " .. content["value"])
      end)
      return true
    end,
    previewer = conf.file_previewer({}),
  })
  picker:find()
end

return M
