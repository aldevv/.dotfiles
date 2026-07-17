-- =========
-- FOLDING
-- =========
vim.o.foldmethod = "expr"
vim.o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.o.foldlevel = 20
vim.o.foldenable = true

-- Per-fold open/closed persistence. mkview/loadview can't capture per-fold
-- state when nvim-ufo manages folding (every fold round-trips as closed), so
-- we save the closed fold ranges ourselves and reapply them after ufo attaches.
local fold_state_dir = vim.fn.stdpath("state") .. "/fold_state"
vim.fn.mkdir(fold_state_dir, "p")

local fold_blacklist = { org = true, OverseerList = true }

local function fold_state_path(bufname)
  return fold_state_dir .. "/" .. bufname:gsub("/", "%%")
end

local function fold_persist_skip(buf)
  if fold_blacklist[vim.bo[buf].filetype] then return true end
  if vim.bo[buf].buftype ~= "" then return true end
  local name = vim.api.nvim_buf_get_name(buf)
  return name == ""
end

local function save_fold_state(buf)
  if fold_persist_skip(buf) then return end
  local closed = {}
  vim.api.nvim_buf_call(buf, function()
    local last = vim.api.nvim_buf_line_count(buf)
    local lnum = 1
    while lnum <= last do
      local s = vim.fn.foldclosed(lnum)
      if s ~= -1 then
        local e = vim.fn.foldclosedend(lnum)
        table.insert(closed, { s, e })
        lnum = e + 1
      else
        lnum = lnum + 1
      end
    end
  end)
  local f = io.open(fold_state_path(vim.api.nvim_buf_get_name(buf)), "w")
  if f then
    f:write(vim.json.encode(closed))
    f:close()
  end
end

local function load_fold_state(buf)
  if fold_persist_skip(buf) then return end
  local f = io.open(fold_state_path(vim.api.nvim_buf_get_name(buf)), "r")
  if not f then return end
  local data = f:read("*a")
  f:close()
  local ok, closed = pcall(vim.json.decode, data)
  if not ok or type(closed) ~= "table" then return end
  vim.api.nvim_buf_call(buf, function()
    pcall(vim.cmd, "silent! normal! zR")
    for _, range in ipairs(closed) do
      pcall(vim.cmd, string.format("silent! %d,%dfoldclose", range[1], range[2]))
    end
  end)
end

local fold_group = vim.api.nvim_create_augroup("remember_folds", { clear = true })
vim.api.nvim_create_autocmd("BufWinLeave", {
  group = fold_group,
  pattern = "?*",
  callback = function(args) save_fold_state(args.buf) end,
})
vim.api.nvim_create_autocmd("BufWinEnter", {
  group = fold_group,
  pattern = "?*",
  callback = function(args)
    -- ufo computes folds asynchronously; wait so the structure exists when we apply.
    vim.defer_fn(function()
      if vim.api.nvim_buf_is_valid(args.buf) then
        load_fold_state(args.buf)
      end
    end, 150)
  end,
})

-- Single-character ops on a closed fold otherwise act on the whole fold; open it first.
local function open_then(key)
  return function()
    if vim.fn.foldclosed(".") ~= -1 then vim.cmd("foldopen") end
    return key
  end
end
for _, key in ipairs({ "x", "X", "r", "~" }) do
  vim.keymap.set("n", key, open_then(key), { expr = true })
end

-- ufo doesn't honor `foldopen=search` for manually-closed folds. On a confirmed
-- /? search (Enter, not Esc), open every fold whose line matches the pattern.
-- Live preview during typing was removed: work in CmdlineChanged clobbered
-- incsearch highlight.
vim.api.nvim_create_autocmd("CmdlineLeave", {
  group = fold_group,
  pattern = { "/", "?" },
  callback = function()
    if vim.v.event.abort then return end
    vim.schedule(function()
      local pattern = vim.fn.getreg("/")
      if pattern ~= "" then
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        for i, line in ipairs(lines) do
          if vim.fn.match(line, pattern) ~= -1 and vim.fn.foldclosed(i) ~= -1 then
            pcall(vim.cmd, string.format("silent! %dfoldopen", i))
          end
        end
      end
      pcall(vim.cmd, "silent! normal! zv")
    end)
  end,
})

for _, key in ipairs({ "*", "#", "g*", "g#" }) do
  vim.keymap.set("n", key, key .. "zv", { noremap = true })
end

-- go to next and prev fold
vim.cmd [[
set foldopen =search,tag,undo,quickfix,percent,mark,insert

nnoremap <silent> zn :<c-u>call RepeatCmd('call NextClosedFold("j")')<cr>
nnoremap <silent> ze :<c-u>call RepeatCmd('call NextClosedFold("k")')<cr>
" for adding a count to NextClosedFold
function! RepeatCmd(cmd) range abort
    let n = v:count < 1 ? 1 : v:count
    while n > 0
        exe a:cmd
        let n -= 1
    endwhile
endfunction

function! NextClosedFold(dir)
    let cmd = 'norm!z'..a:dir
    let view = winsaveview()
    let [l0, l, open] = [0, view.lnum, 1]
    while l != l0 && open
        exe cmd
        let [l0, l] = [l, line('.')]
        let open = foldclosed(l) < 0
    endwhile
    if open
        call winrestview(view)
    endif
endfunction
]]
