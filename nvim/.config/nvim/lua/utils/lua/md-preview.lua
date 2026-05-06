-- md-preview.lua — Neovim scroll-synced markdown preview
-- Single-instance: open → server + Chrome + tmux pane
--                  re-open → replace content, no new server/window

local M = {}

M.state = {
  job_id         = nil,   -- jobstart() channel ID
  port           = 9753,
  file           = nil,   -- absolute path currently previewed
  tmux_pane_id   = nil,   -- "%12" style tmux pane ID (Linux/tmux)
  debounce_timer = nil,   -- vim.loop timer for cursor debounce
  platform       = nil,   -- "linux" or "macos"
  augroup        = nil,   -- autocmd group ID
}

local function log(msg)
  vim.notify("[md-preview] " .. msg, vim.log.levels.INFO)
end

local function err(msg)
  vim.notify("[md-preview] " .. msg, vim.log.levels.ERROR)
end

-- ── Compat: vim.uv (0.10+) or vim.loop ───────────────────────────────────
local uv = vim.uv or vim.loop

-- ── Platform detection ────────────────────────────────────────────────────

function M.setup()
  local uname = uv.os_uname()
  if uname.sysname == "Darwin" then
    M.state.platform = "macos"
  else
    M.state.platform = "linux"
  end
end

-- ── Server health check ───────────────────────────────────────────────────

function M.is_alive()
  if M.state.job_id == nil then return false end
  return vim.fn.jobwait({ M.state.job_id }, 0)[1] == -1
end

-- ── IPC: send JSON to server stdin ────────────────────────────────────────

local function send(msg)
  if not M.is_alive() then return end
  vim.fn.chansend(M.state.job_id, vim.json.encode(msg) .. "\n")
end

-- ── Poll until server is ready ────────────────────────────────────────────

local function poll_ready(port, on_ready, retries)
  retries = retries or 0
  if retries > 200 then
    err("Server did not start on port " .. port)
    return
  end
  vim.defer_fn(function()
    local ok = pcall(vim.fn.system, "curl -sf --max-time 0.1 http://localhost:" .. port .. "/reload")
    if ok and vim.v.shell_error == 0 then
      on_ready()
    else
      poll_ready(port, on_ready, retries + 1)
    end
  end, 50)
end

-- ── Autocmds ─────────────────────────────────────────────────────────────

local function register_autocmds()
  if M.state.augroup then
    vim.api.nvim_del_augroup_by_id(M.state.augroup)
  end
  local aug = vim.api.nvim_create_augroup("MdPreview", { clear = true })
  M.state.augroup = aug

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = aug,
    pattern = "*.md",
    callback = function()
      M.on_save()
    end,
  })

  vim.api.nvim_create_autocmd("CursorHold", {
    group = aug,
    pattern = "*.md",
    callback = function()
      M.on_cursor_moved()
    end,
  })

  vim.api.nvim_create_autocmd("BufWipeout", {
    group = aug,
    pattern = "*.md",
    callback = function()
      local f = vim.fn.expand("<afile>:p")
      if f == M.state.file then
        M.close()
      end
    end,
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = aug,
    callback = function()
      M.close()
    end,
  })
end

-- ── tmux pane management ──────────────────────────────────────────────────

local function in_tmux()
  return os.getenv("TMUX") ~= nil
end

local function tmux_open_pane(cmd)
  -- Split right 45%, run cmd, capture pane ID
  local pane_id = vim.fn.system("tmux split-window -h -l 45% -P -F '#{pane_id}' " .. vim.fn.shellescape(cmd))
  pane_id = pane_id:gsub("%s+", "")
  return pane_id ~= "" and pane_id or nil
end

local function tmux_kill_pane(pane_id)
  if pane_id then
    vim.fn.system("tmux kill-pane -t " .. vim.fn.shellescape(pane_id))
  end
end

-- ── Open browser ─────────────────────────────────────────────────────────

local function open_browser()
  local url = "http://localhost:" .. M.state.port .. "/"
  if M.state.platform == "macos" then
    -- Open Chrome app window, then tile it to the right of kitty
    local script = string.format([[
-- Get screen bounds
tell application "Finder"
  set db to bounds of window of desktop
end tell
set screenLeft   to item 1 of db
set screenTop    to item 2 of db
set screenRight  to item 3 of db
set screenBottom to item 4 of db
set screenW to screenRight - screenLeft
set screenH to screenBottom - screenTop
set chromeX to screenLeft + (screenW * 6 div 10)
set chromeW to screenW - (screenW * 6 div 10)
-- Always tile kitty to left 60% of screen
tell application "System Events"
  tell process "kitty"
    set position of window 1 to {screenLeft, screenTop}
    set size     of window 1 to {screenW * 6 div 10, screenH}
  end tell
end tell
-- Open Chrome app window
do shell script "open -na 'Google Chrome' --args --app=%s"
-- Wait for Chrome window via System Events (up to 10 s)
repeat 20 times
  delay 0.5
  try
    tell application "System Events"
      tell process "Google Chrome"
        if (count windows) > 0 then exit repeat
      end tell
    end tell
  end try
end repeat
-- Position Chrome on the right 40%%
tell application "System Events"
  tell process "Google Chrome"
    set position of window 1 to {chromeX, screenTop}
    set size     of window 1 to {chromeW, screenH}
  end tell
end tell
]], url)
    vim.fn.jobstart({ "osascript", "-e", script }, { detach = true })
  else
    -- Linux
    if in_tmux() then
      local cmd = vim.fn.executable("devour") == 1
          and ("devour chromium --app=" .. url)
          or ("chromium --app=" .. url)
      M.state.tmux_pane_id = tmux_open_pane(cmd)
    else
      local chrome = vim.fn.executable("google-chrome") == 1 and "google-chrome"
          or vim.fn.executable("chromium") == 1 and "chromium"
          or vim.fn.executable("chromium-browser") == 1 and "chromium-browser"
          or nil
      if chrome then
        vim.fn.jobstart({ chrome, "--app=" .. url }, { detach = true })
      else
        err("No Chrome/Chromium found")
      end
    end
  end
end

-- ── Main API ──────────────────────────────────────────────────────────────

function M.open(theme)
  theme = theme or "dark"
  local file = vim.fn.expand("%:p")

  if not file:match("%.md$") then
    err("Not a markdown file")
    return
  end

  -- Already running: switch file only
  if M.is_alive() then
    M.state.file = file
    send({ type = "render", file = file })
    log("Switched preview to " .. vim.fn.fnamemodify(file, ":t"))
    return
  end

  M.state.file = file

  local server_script = vim.fn.stdpath("config") .. "/scripts/md-preview-server.py"
  local venv_python = vim.fn.expand("~/.local/share/nvim/md-preview-venv/bin/python3")
  local python = vim.fn.filereadable(venv_python) == 1 and venv_python or "python3"

  M.state.job_id = vim.fn.jobstart(
    { python, server_script, file, tostring(M.state.port), theme },
    {
      stdin = "pipe",
      stdout_buffered = false,
      stderr_buffered = false,
      on_stdout = function(_, data)
        for _, line in ipairs(data) do
          if line ~= "" then log(line) end
        end
      end,
      on_stderr = function(_, data)
        for _, line in ipairs(data) do
          if line ~= "" then err(line) end
        end
      end,
      on_exit = function(_, code)
        if code ~= 0 then
          err("Server exited with code " .. code)
        end
        M.state.job_id = nil
        M.state.tmux_pane_id = nil
      end,
    }
  )

  if M.state.job_id <= 0 then
    err("Failed to start server")
    M.state.job_id = nil
    return
  end

  log("Starting server for " .. vim.fn.fnamemodify(file, ":t") .. "…")

  poll_ready(M.state.port, function()
    log("Server ready — opening browser")
    open_browser()
    register_autocmds()
  end)
end

-- ── Cursor moved (debounced 150ms) ────────────────────────────────────────

function M.on_cursor_moved()
  if not M.is_alive() then return end

  -- Cancel existing timer
  if M.state.debounce_timer then
    M.state.debounce_timer:stop()
    M.state.debounce_timer:close()
    M.state.debounce_timer = nil
  end

  local timer = uv.new_timer()
  M.state.debounce_timer = timer
  timer:start(150, 0, vim.schedule_wrap(function()
    timer:stop()
    timer:close()
    M.state.debounce_timer = nil
    if not M.is_alive() then return end
    -- cursor row is 1-indexed; server expects 0-indexed
    local row = vim.api.nvim_win_get_cursor(0)[1] - 1
    send({ type = "scroll", line = row })
  end))
end

-- ── Save ──────────────────────────────────────────────────────────────────

function M.on_save()
  if not M.is_alive() then return end
  local file = vim.fn.expand("%:p")
  M.state.file = file
  send({ type = "render", file = file })
end

-- ── Close ─────────────────────────────────────────────────────────────────

function M.close()
  if M.state.debounce_timer then
    pcall(function()
      M.state.debounce_timer:stop()
      M.state.debounce_timer:close()
    end)
    M.state.debounce_timer = nil
  end

  if M.is_alive() then
    send({ type = "quit" })
    vim.fn.jobstop(M.state.job_id)
  end

  if M.state.tmux_pane_id then
    tmux_kill_pane(M.state.tmux_pane_id)
  end

  if M.state.augroup then
    pcall(vim.api.nvim_del_augroup_by_id, M.state.augroup)
  end

  M.state.job_id       = nil
  M.state.file         = nil
  M.state.tmux_pane_id = nil
  M.state.augroup      = nil

  log("Preview closed")
end

return M
