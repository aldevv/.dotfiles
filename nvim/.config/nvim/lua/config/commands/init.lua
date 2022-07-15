vim.cmd([[command! -nargs=+ Put :put=execute('<args>')]])
-- vim.api.nvim_create_user_command('Print', 'echo <q-args>', { nargs ='*'})
