autocmd! BufRead,BufNewFile docker-compose.yml  set filetype=docker-compose.yml syntax=yaml ts=2 sts=2 sw=2 expandtab
au! BufNewFile,BufReadPost *.{yaml,yml} setfiletype=yaml foldmethod=indent ts=2 sts=2 sw=2 expandtab

