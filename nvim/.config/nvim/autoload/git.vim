function git#push(path, comment)
  let git_command = 'git -C ' . a:path
  let add = git_command .  ' add . ' 
  let commit = git_command . ' commit -m ' . a:comment . ' '
  let push = git_command . ' push origin master'
  silent exec 'Start! -wait=never ' . add . '&& ' . commit . '&& ' . push
endfunction

function! git#find_current_root(...)
  if a:0 != 1
    execute ':lcd %:p:h'
  endif
    return system('git status') =~ '^fatal:' ?
                \ expand("%:p:h") : system("git rev-parse --show-toplevel 2> /dev/null")[:-2]
endfunction

function! git#is_repo()
    execute ':lcd %:p:h'
    return system('git status') =~ '^fatal:' ? 0 : 1
endfunction

function! git#diff_any_branch(branch)
  call feedkeys("i", "n")
  if !git#is_repo()
    return
  endif

  let l:root = git#find_current_root()
  let l:current_dir = system("pwd")
  exec 'lcd '. l:root

  let l:branch_files = split(system('git ls-tree' . a:branch . ' -r --name-only'), '\n')
  call fzf#run(fzf#wrap({'source': l:branch_files, 'sink': function ('s:load_file') }))
  exec 'lcd ' . l:current_dir
endfunction

function! s:load_file(output)
call feedkeys("i", "n")
exec 'Gdiff ' . a:output
endfunction


