vim.treesitter.language.register("bash", "zsh")
vim.treesitter.language.register("markdown", "octo")

local ensure_installed = {
  "vimdoc",
  "bash",
  "python",
  "css",
  "rust",
  "javascript",
  "typescript",
  "tsx",
  "go",
  "gomod",
  "gosum",
  "gowork",
  "sql",
  "json",
  "dockerfile",
  "make",
  "cmake",
  "markdown",
  "markdown_inline",
  "yaml",
  "http",
  "zig",
  "jsdoc",
  "lua",
  "luadoc",
  "gpg",
  "awk",
  "toml",
  "sxhkdrc",
  "svelte",
  "requirements",
  "ini",
  "html",
  "gitignore",
  "gitcommit",
  "gitattributes",
  "git_rebase",
  "git_config",
  "csv",
  "terraform",
}
if os.getenv("NVIM_MINIMAL") ~= nil then
  ensure_installed = {}
end

if vim.fn.executable("tree-sitter") == 1 then
  require("nvim-treesitter").install(ensure_installed)
else
  vim.notify(
    "tree-sitter CLI not found: required by nvim-treesitter (main branch) to build parsers. "
      .. "Install it (>= 0.26.1, not via npm), then run :TSUpdate.",
    vim.log.levels.WARN
  )
end

-- Preload heavy/common parsers into memory so the FIRST buffer of each
-- doesn't pay the parser-load cost on demand. Markdown's first open used
-- to take ~2s because render-markdown waits for treesitter to load the
-- parser before its first decoration pass.
local preload = { "markdown", "markdown_inline" }
vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("ts_preload", { clear = true }),
  once = true,
  callback = function()
    vim.schedule(function()
      for _, lang in ipairs(preload) do
        pcall(vim.treesitter.language.add, lang)
      end
    end)
  end,
})

local function is_big_file(buf)
  local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
  return ok and stats and stats.size > 100 * 1024
end

local ft_aliases = { zsh = "bash", octo = "markdown" }

local group = vim.api.nvim_create_augroup("user_treesitter", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  callback = function(args)
    local buf = args.buf
    if is_big_file(buf) then
      return
    end
    local lang = ft_aliases[args.match] or args.match
    if not pcall(vim.treesitter.start, buf, lang) then
      return
    end
    vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})
