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

require("nvim-treesitter").install(ensure_installed)

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
