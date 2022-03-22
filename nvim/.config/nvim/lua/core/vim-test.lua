-- " PROJECTIONIST INTEGRATION                       *test-projectionist*

-- " If the |projectionist| plug-in is present, you can run a test command from an
-- " application file, and test.vim will automatically try to run the
-- " command on the "alternate" test file.
--
-- " You can disable this integration by doing
-- " >
--   " let g:test#no_alternate = 1
-- " <

-- " let test#strategy = "dispatch"
-- " let test#strategy = "harpoon" -- TODO check this

-- let test#strategy = {
--   \ 'nearest': 'neovim',
--   \ 'file':    'dispatch',
--   \ 'suite':   'basic',
-- \}
-- vim.cmd([[let test#strategy = "neovim"
vim.cmd([[let test#strategy = "harpoon"

autocmd BufReadPost * let test#project_root = git#find_current_root(1)

augroup TestType
    autocmd User ProjectionistActivate call <SID>get_testrunner()
augroup END

function s:get_testrunner()
  " better way to do this? FileType autocmd didnt work

  " if defined in projectionist, choose it, otherwise, let the plugin choose
  let l:value = projectionist#query('testrunner')
  if len(value) < 1
    return
  endif
  let l:value = l:value[-1][1]
  let l:extensions = ['ts', 'scala', 'js', 'py', 'java', 'rs', 'go', 'php']

  if index(l:extensions, g:extension) >= 0 " si esta en el arreglo
    if g:extension == "py"
      let g:test#python#runner = l:value
      return
    endif
    if g:extension == "java"
      let g:test#java#runner = l:value
      return
    endif
    if g:extension == "ts"
      let g:test#typescript#runner = l:value
      return
    endif
    if g:extension == "js"
      let g:test#javascript#runner = l:value
      return
    endif
    if g:extension == "go"
      let g:test#go#runner = l:value
      return
    endif
    if g:extension == "rs"
      let g:test#rust#runner = l:value
      return
    endif
    if g:extension == "scala"
      let g:test#scala#runner = l:value
      return
    endif
    if g:extension == "php"
      let g:test#php#runner = l:value
      return
    endif
  endif
endfunction

function s:choose_test_runner()
autocmd FileType python let g:test#python#runner = projectionist#query('testrunner')[0][1]
autocmd FileType javascript,typescript let g:test#javascript#runner = projectionist#query('testrunner')[0][1]
  autocmd FileType java let g:test#java#runner = projectionist#query('testrunner')[0][1]
  autocmd FileType go let g:test#go#runner = projectionist#query('testrunner')[0][1]
  autocmd FileType scala let g:test#scala#runner = projectionist#query('testrunner')[0][1]
  autocmd FileType php let g:test#php#runner = projectionist#query('testrunner')[0][1]
endfunction


" let test#strategy = "neoterm"
" let g:test#runner_commands = ['DjangoTest']
" Runners available are 'gotest', 'ginkgo', 'richgo', 'delve'
" let test#java#runner = 'gradletest'
" let test#php#phpunit#executable = 'phpunit artisan test'

" The following setup will automatically run tests when a test file or its alternate application file is saved:

" augroup test
"   autocmd!
"   autocmd BufWrite * if test#exists() |
"     \   TestFile |
"     \ endif
" augroup END
]])
