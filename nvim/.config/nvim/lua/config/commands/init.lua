vim.cmd([[command! -nargs=+ Put :put=execute('<args>')]])
-- vim.cmd([[command! -nargs=+ Vnew :vnew | :set ft=<args>]]) --> not working
-- vim.api.nvim_create_user_command('Print', 'echo <q-args>', { nargs ='*'})
