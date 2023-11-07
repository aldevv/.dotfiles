local M = {}

local popup = require("plenary.popup")

float_win_id = nil
float_bufnr = nil

local function get_title_from_filename(file)
  -- if file doesn't contain a dot return file
  if file:find("%.") == nil then
    return file
  end
  local title

  -- remove initial dot
  if file:sub(0, 1) == "." then
    title = file:sub(1)
  end

  -- remove extension
  local extension_idx = file:find("%.")
  if extension_idx ~= nil then
    title = file:sub(0, extension_idx - 1)
  end

  -- make first character uppercase
  title = title:sub(0, 1):upper() .. title:sub(2)
  return title
end

-- TODO: load a yaml file that saves project level files to float (use harpoon?)
local function create_window(file, config)
  local title = get_title_from_filename(file)
  local curdir = vim.b.netrw_curdir
  local ft = vim.o.filetype

  local config = config or {}
  local width = config.width or 60
  local height = config.height or 25
  -- local height = config.height or 30
  local borderchars = config.borderchars or { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }

  local current_id = vim.api.nvim_get_current_buf()
  vim.api.nvim_command(":e " .. file)
  float_bufnr = vim.api.nvim_get_current_buf()

  if ft ~= "netrw" then
    -- go back to file i was in
    vim.api.nvim_set_current_buf(current_id)
  else
    -- open the dir I was in
    print("yep")
    vim.cmd("Ex" .. curdir)
  end

  float_win_id, _ = popup.create(float_bufnr, {
    title = title,
    highlight = "FloatWindow",
    line = math.floor(((vim.o.lines - height) / 2) - 1),
    col = math.floor((vim.o.columns - width) / 2),
    minwidth = width,
    minheight = height,
    maxheight = height,
    borderchars = borderchars,
  })
end

M.toggle = function(file, config)
  local config = config or {}
  if float_win_id ~= nil and vim.api.nvim_win_is_valid(float_win_id) then
    -- to close it quickly without saving or anything
    vim.api.nvim_win_close(float_win_id, true)
    float_win_id = nil
    float_bufnr = nil
    return
  end

  -- create floating window with file inside
  create_window(file, config)
  vim.api.nvim_buf_set_option(float_bufnr, "bufhidden", "delete")

  -- keymaps
  local exists = vim.fn.glob(file)
  local save_if_exists = function()
    if exists ~= "" then
      vim.cmd("wq")
    else
      vim.cmd("q")
    end
  end
  vim.keymap.set("n", "q", save_if_exists, { buffer = float_bufnr, silent = true })
end

return M
