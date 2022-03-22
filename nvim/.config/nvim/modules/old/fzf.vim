" =======
" FZF  (to change ignored files, change the .rgignore)
" =======
" :Colors
" :Commands
" :Maps
" :Snippets
" :Helptags
"
" call fzf#vim#complete#path($FZF_DEFAULT_COMMAND)
" \ 'ctrl-t': 'tab split',
"" defaults
let $FZF_DEFAULT_OPTS = ' --height=15 --layout=reverse --multi --bind=alt-e:up,alt-n:down,+:toggle-preview,ctrl-a:select-all+accept'
let g:fzf_preview_window = ['right:50%', '+']
" hidden by default, ctrl-/ to toggle
" let g:fzf_preview_window = ['up:40%:hidden', '+']

let g:fzf_layout = { 'window': { 'width': 0.6, 'height': 0.6 } }
let g:fzf_action = {
            \ 'ctrl-s': 'split',
            \ 'ctrl-v': 'vsplit',
            \ 'ctrl-o': 'silent !setsid st -e nvim 2>/dev/null' } " sends it to other nvim instance
" for rg
let g:rg_derive_root='true'
set grepprg=rg\ --vimgrep\ --smart-case\ --hidden\ --follow
nnoremap <a-p> :Filescwd<cr>
nnoremap <a-P> :GFiles<cr>
nnoremap <c-p> :Buffers<cr>
nnoremap <C-S-P> :Commits<cr>
  command! -bang Commits call fzf#vim#commits({'options': '--no-preview'}, <bang>0)
nnoremap <leader>ac :Commands<cr>
" <c-c> is viable too
nnoremap <leader>am :Maps<cr>
" TODO, make it auto from the bookmarks files
nnoremap <localleader>ms :FilesScripts<cr>
nnoremap <localleader>v :FilesVim<cr>
nnoremap <localleader>M  :FilesMaster<cr>
nnoremap <localleader>sp :FilesSnips<cr>
nnoremap <localleader>h :FilesHome<cr>
nnoremap <localleader>wo :FilesWork<cr>
nnoremap <localleader>cc :FilesClass<cr>
nnoremap <localleader>po :FilesProjects<cr>
nnoremap <localleader>pr :FilesPrograms<cr>
nnoremap <localleader>cf :FilesDots<cr>
nnoremap <localleader>mo :FilesOs<cr>
nnoremap <leader>sN :RemoveFiles<cr>
nnoremap <leader>sF :RemoveDirs<cr>

nnoremap <localleader>,cfv :e $XDG_CONFIG_HOME/nvim/init.lua<cr>

"made myself
nnoremap <BS>b :Bookm<cr>
nnoremap <leader>sb :Buffers<cr>
let g:vista_default_executive = 'ctags'
" nnoremap <F4> :Course<cr>
let g:fzf_commits_log_options = '--graph --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr"'

command! -bang -nargs=? -complete=dir FilesVim
            \ call fzf#vim#files(<q-args>, fzf#vim#with_preview({'dir':$XDG_CONFIG_HOME . "/nvim", 'options': ['--layout=reverse', '--info=inline']}), <bang>0)

command! -bang -nargs=? -complete=dir FilesScripts
            \ call fzf#vim#files(<q-args>, fzf#vim#with_preview({'dir':$SCRIPTS, 'options': ['--layout=reverse', '--info=inline']}), <bang>0)

command! -bang -nargs=? -complete=dir FilesHome
            \ call fzf#vim#files(<q-args>, fzf#vim#with_preview({'dir':$HOME, 'options': ['--layout=reverse', '--info=inline']}), <bang>0)

command! -bang -nargs=? -complete=dir FilesMaster
            \ call fzf#vim#files(<q-args>, fzf#vim#with_preview({'dir':$MASTER, 'options': ['--layout=reverse', '--info=inline']}), <bang>0)

command! -bang -nargs=? -complete=dir FilesWork
            \ call fzf#vim#files(<q-args>, fzf#vim#with_preview({'dir':$WORK, 'options': ['--layout=reverse', '--info=inline']}), <bang>0)

command! -bang -nargs=? -complete=dir FilesClass
            \ call fzf#vim#files(<q-args>, fzf#vim#with_preview({'dir':$CLASS, 'options': ['--layout=reverse', '--info=inline']}), <bang>0)

command! -bang -nargs=? -complete=dir FilesProjects
            \ call fzf#vim#files(<q-args>, fzf#vim#with_preview({'dir':$PROJECTS, 'options': ['--layout=reverse', '--info=inline']}), <bang>0)

command! -bang -nargs=? -complete=dir FilesDots
            \ call fzf#vim#files(<q-args>, fzf#vim#with_preview({'dir':$XDG_CONFIG_HOME, 'options': ['--layout=reverse', '--info=inline']}), <bang>0)

command! -bang -nargs=? -complete=dir FilesLearn
            \ call fzf#vim#files(<q-args>, fzf#vim#with_preview({'dir':$LEARN, 'options': ['--layout=reverse', '--info=inline']}), <bang>0)

command! -bang -nargs=? -complete=dir FilesPrograms
          \ call fzf#vim#files(<q-args>, fzf#vim#with_preview({'dir':$PROGRAMS, 'options': ['--layout=reverse', '--info=inline']}), <bang>0)

command! -bang -nargs=? -complete=dir FilesOs
            \ call fzf#vim#files(<q-args>, fzf#vim#with_preview({'dir':$OS, 'options': ['--layout=reverse', '--info=inline']}), <bang>0)

let snips_folder=$XDG_CONFIG_HOME."/nvim/my_snippets"
command! -bang -nargs=? -complete=dir FilesSnips
            \ call fzf#vim#files(<q-args>, fzf#vim#with_preview({'dir':snips_folder, 'options': ['--layout=reverse', '--info=inline']}), <bang>0)

" gives a preview window to Files
command! -bang -nargs=? -complete=dir Filescwd
            \ call fzf#vim#files(<q-args>, fzf#vim#with_preview({'options': ['--layout=reverse', '--info=inline'], 'dir': getcwd()}), <bang>0)

" overwrites GFILES (user git-ls which doesn't find files not in repo)
command! -bang -nargs=? -complete=dir Files
            \ call fzf#vim#files(<q-args>, fzf#vim#with_preview({'options': ['--layout=reverse', '--info=inline']}), <bang>0)

" to start fzf at root of project
command! GFiles execute 'Files' git#find_current_root()

function RemoveFileUpdateNerdtree(files)
  exec system('rm ' . a:files)
  if !SpecialWindow()
    :w
  endif
  if exists("g:NERDTree") && g:NERDTree.IsOpen()
    :NERDTreeRefreshRoot
  endif
endfunction

" TODO modify!!, not needed anymore

let remove_files_command = "rg --files -uu --no-heading --follow --ignore-file=". $RG_IGNORE_FILE." --"
let remove_dir_command = "fd -t d -H -d 1""
function RemoveDirUpdateNerdtree(dir)
  exec system('rm -r ' . a:dir)
  if !SpecialWindow()
    :w
  endif
  if exists("g:NERDTree") && g:NERDTree.IsOpen()
    :NERDTreeRefreshRoot
  endif
endfunction

"----------------------------------------------------------------
command! -bang -bar -nargs=1 -complete=dir RemoveFiles
            \ call fzf#vim#files(<q-args>, fzf#vim#with_preview(
            \ {
            \   'source': remove_files_command,
            \   'sink': function('RemoveFileUpdateNerdtree'),
            \   'options': ['--layout=reverse', '--info=inline']
            \ }), <bang>0)


command! -bang -bar -nargs=1 -complete=dir RemoveDirs
            \ call fzf#vim#files(<q-args>, fzf#vim#with_preview(
            \ {
            \   'source': remove_dir_command,
            \   'sink': function('RemoveDirUpdateNerdtree'),
            \   'options': ['--layout=reverse', '--info=inline']
            \ }), <bang>0)
"----------------------------------------------------------------

" for ripgrep
" command! -bang -nargs=* Rgfzf
"             \ call fzf#vim#grep(
"             \   'rg --column --line-number --no-heading --color=always --smart-case -- '.shellescape(<q-args>), 1,
"             \   fzf#vim#with_preview({'window':{'width':1,  'height':0.7},'dir': s:find_current_root()}), <bang>0)
let rg_command_nofiles = "rg --column --no-heading --color=always --smart-case --line-number --follow --ignore-file=". $RG_IGNORE_FILE." --"
command! -bang -nargs=* Rgfzf
            \ call fzf#vim#grep(
            \   rg_command_nofiles . ' ' . shellescape(<q-args>), 1,
            \   fzf#vim#with_preview({'window':{'width':1,  'height':0.7},'dir': git#find_current_root()}), <bang>0)
map <leader>f :Rgfzf<cr>

command! -bang -nargs=* RgfzfCurrentWord
            \ call fzf#vim#grep(
            \   rg_command_nofiles . ' ' . shellescape(expand('<cword>')), 1,
            \   fzf#vim#with_preview({'window':{'width':1,  'height':0.7},'dir': git#find_current_root()}), <bang>0)
map <leader>F :RgfzfCurrentWord<cr>


let commandFiles="awk '{print $2}' ".$XDG_CONFIG_HOME."/shortcuts/sd"
command! -bang -nargs=* Bookm call fzf#run(fzf#vim#with_preview(fzf#wrap({'source':commandFiles,'sink': 'e'})))

command! -bang -nargs=* Diffany call fzf#run(fzf#wrap({'source':'git branch', 'sink': function('git#diff_any_branch')}))
nnoremap <leader>gda :Diffany<CR>


"search in specific folder"
" command! -bang Course call fzf#vim#files('~/Documents/Learn/languages', <bang>0)

"Or, if you want to override the command with different fzf options, just pass a custom spec to the function.
"command! -bang -nargs=? -complete=dir Files
"   \ call fzf#vim#files(<q-args>, {'options': ['--layout=reverse', '--info=inline']}, <bang>0)
"
" list functions
" nnoremap <leader>ff :FFunc<CR>
" from https://github.com/
" nnoremap <leader>fs :FZFBTags<CR>
" nnoremap <leader>fc :FClass<CR>


