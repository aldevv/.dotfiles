function utils#focus_window(window)
  if type(a:window) == 1
    " is a string, so get the number
    let a:window = bufwinnr(a:window)
  endif

  if a:window == -1
    return
  endif

  execute a:window 'wincmd w'
  endfunction
