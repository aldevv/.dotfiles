if !isdirectory($HOME . '/.local/share/nvim/site') && !isdirectory($XDG_CONFIG_HOME . '/nvim/site')
    exec ':!'.$HOME.'/.config/nvim/install_plug'
endif

if len($PKG) != 0
  let pkg_manager = $PKG
  let pkg_install = 'sudo ' . $PKG_COMMAND
else
  let pkg_options = {'eopkg': 'sudo eopkg install', 'apt': 'sudo apt-get install', 'pacman': 'sudo pacman -S'}
  for [key, value] in items(pkg_options)
    if executable(key)
      let pkg_manager = key
      let pkg_install = value
      break
    endif
  endfor
endif


if !executable('npm') && !executable('yarn') && !IS_MINE
  exec ":!" . pkg_install . " npm"
endif

if !executable('node') && !IS_MINE
  exec ":!" . pkg_install . " nodejs"
endif

if !executable('pip3') && !IS_MINE
  exec ":!" . pkg_install . " pip3"
endif


if !filereadable($HOME . '/.local/bin/black') && executable('pip3') && $USER != 'root'
    :!pip3 install black
endif

if !executable('prettier') && $USER != 'root'
  if executable('yarn')
    if isdirectory($HOME . '/.config/nvm/')
      :!yarn global add prettier
    else
      :!sudo yarn global add prettier
    endif
  else
    if executable('npm')
      if isdirectory($HOME . '/.config/nvm/')
        :!npm install -g prettier
      else
        :!sudo npm install -g prettier
      endif
    endif
  endif
endif

if !filereadable($HOME . '/.local/bin/clang-format') && executable('pip3') && $USER != 'root'
    :!pip3 install clang-format
endif

" if !executable('uncrustify')
"     :!sudo eopkg install uncrustify
" endif

