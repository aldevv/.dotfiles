--
function _G._is_work_env()
    return vim.fn.system "cd ~/.dotfiles; git branch --show-current | tr -d '\\n'; cd -" == "work"
end
