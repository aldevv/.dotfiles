--
-- these are loaded so you can do : lua put({1,2,3})
function _G._replace_termcodes(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

function _G.is_work_env()
  return vim.fn.system("cd ~/.dotfiles; git branch --show-current | tr -d '\\n'; cd -") == "work"
end
