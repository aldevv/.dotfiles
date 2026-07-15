-- AUTO GENERATED FILE, DO NOT MODIFY MANUALLY, UPDATE THE shortcuts script

vim.keymap.set("n", "<backspace>H", "<cmd>e ~<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>H", ":lua require('telescope.builtin').find_files({prompt_title = '<~>', cwd = '~', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>H", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~>', cwd = '~', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>d.", "<cmd>e ~/.dotfiles<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>d.", ":lua require('telescope.builtin').find_files({prompt_title = '<~/.dotfiles>', cwd = '~/.dotfiles', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>d.", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~/.dotfiles>', cwd = '~/.dotfiles', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>uu", "<cmd>e /home/kanon/remotes<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>uu", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/remotes>', cwd = '/home/kanon/remotes', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>uu", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/remotes>', cwd = '/home/kanon/remotes', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>rr", "<cmd>e ~/repos<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>rr", ":lua require('telescope.builtin').find_files({prompt_title = '<~/repos>', cwd = '~/repos', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>rr", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~/repos>', cwd = '~/repos', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>n.", "<cmd>e /home/kanon/notes<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>n.", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/notes>', cwd = '/home/kanon/notes', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>n.", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/notes>', cwd = '/home/kanon/notes', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>N.", "<cmd>e /home/kanon/notes/atomic<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>N.", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/notes/atomic>', cwd = '/home/kanon/notes/atomic', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>N.", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/notes/atomic>', cwd = '/home/kanon/notes/atomic', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>wo", "<cmd>e /home/kanon/work<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>wo", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/work>', cwd = '/home/kanon/work', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>wo", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/work>', cwd = '/home/kanon/work', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>bk", "<cmd>e /home/kanon/books<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>bk", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/books>', cwd = '/home/kanon/books', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>bk", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/books>', cwd = '/home/kanon/books', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>bK", "<cmd>e /home/kanon/books/ln<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>bK", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/books/ln>', cwd = '/home/kanon/books/ln', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>bK", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/books/ln>', cwd = '/home/kanon/books/ln', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>ba", "<cmd>e /home/kanon/.local/share/.backups<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>ba", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/.local/share/.backups>', cwd = '/home/kanon/.local/share/.backups', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>ba", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/.local/share/.backups>', cwd = '/home/kanon/.local/share/.backups', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>ll", "<cmd>e /home/kanon/learn<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>ll", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/learn>', cwd = '/home/kanon/learn', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>ll", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/learn>', cwd = '/home/kanon/learn', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>l.", "<cmd>e /home/kanon/learn<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>l.", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/learn>', cwd = '/home/kanon/learn', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>l.", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/learn>', cwd = '/home/kanon/learn', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>b.", "<cmd>e /home/kanon/.local/builds<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>b.", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/.local/builds>', cwd = '/home/kanon/.local/builds', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>b.", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/.local/builds>', cwd = '/home/kanon/.local/builds', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>T.", "<cmd>e /home/kanon/.local/share/Trash/files<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>T.", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/.local/share/Trash/files>', cwd = '/home/kanon/.local/share/Trash/files', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>T.", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/.local/share/Trash/files>', cwd = '/home/kanon/.local/share/Trash/files', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>Tt", "<cmd>e /home/kanon/.local/share/Trash/files<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>Tt", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/.local/share/Trash/files>', cwd = '/home/kanon/.local/share/Trash/files', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>Tt", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/.local/share/Trash/files>', cwd = '/home/kanon/.local/share/Trash/files', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>Tr", "<cmd>e /home/kanon/Downloads/torrents<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>Tr", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/Downloads/torrents>', cwd = '/home/kanon/Downloads/torrents', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>Tr", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/Downloads/torrents>', cwd = '/home/kanon/Downloads/torrents', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>sk", "<cmd>e /home/kanon/programs/suckless<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>sk", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/programs/suckless>', cwd = '/home/kanon/programs/suckless', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>sk", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/programs/suckless>', cwd = '/home/kanon/programs/suckless', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>f.", "<cmd>e /home/kanon/.config<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>f.", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/.config>', cwd = '/home/kanon/.config', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>f.", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/.config>', cwd = '/home/kanon/.config', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>v.", "<cmd>e /home/kanon/.config/nvim<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>v.", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/.config/nvim>', cwd = '/home/kanon/.config/nvim', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>v.", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/.config/nvim>', cwd = '/home/kanon/.config/nvim', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>vl", "<cmd>e /home/kanon/.config/nvim/lua/config/plugins/lsp<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>vl", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/.config/nvim/lua/config/plugins/lsp>', cwd = '/home/kanon/.config/nvim/lua/config/plugins/lsp', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>vl", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/.config/nvim/lua/config/plugins/lsp>', cwd = '/home/kanon/.config/nvim/lua/config/plugins/lsp', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>va", "<cmd>e /home/kanon/.config/nvim/lua/config/automation<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>va", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/.config/nvim/lua/config/automation>', cwd = '/home/kanon/.config/nvim/lua/config/automation', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>va", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/.config/nvim/lua/config/automation>', cwd = '/home/kanon/.config/nvim/lua/config/automation', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>vt", "<cmd>e /home/kanon/.config/nvim/lua/ui/themes<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>vt", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/.config/nvim/lua/ui/themes>', cwd = '/home/kanon/.config/nvim/lua/ui/themes', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>vt", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/.config/nvim/lua/ui/themes>', cwd = '/home/kanon/.config/nvim/lua/ui/themes', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>vc", "<cmd>e /home/kanon/.config/nvim/lua/config/plugins<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>vc", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/.config/nvim/lua/config/plugins>', cwd = '/home/kanon/.config/nvim/lua/config/plugins', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>vc", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/.config/nvim/lua/config/plugins>', cwd = '/home/kanon/.config/nvim/lua/config/plugins', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>vC", "<cmd>e /home/kanon/.config/nvim/lua/config<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>vC", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/.config/nvim/lua/config>', cwd = '/home/kanon/.config/nvim/lua/config', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>vC", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/.config/nvim/lua/config>', cwd = '/home/kanon/.config/nvim/lua/config', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>vu", "<cmd>e /home/kanon/.config/nvim/lua/utils<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>vu", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/.config/nvim/lua/utils>', cwd = '/home/kanon/.config/nvim/lua/utils', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>vu", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/.config/nvim/lua/utils>', cwd = '/home/kanon/.config/nvim/lua/utils', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>vk", "<cmd>e /home/kanon/.config/nvim/lua/keybindings<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>vk", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/.config/nvim/lua/keybindings>', cwd = '/home/kanon/.config/nvim/lua/keybindings', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>vk", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/.config/nvim/lua/keybindings>', cwd = '/home/kanon/.config/nvim/lua/keybindings', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>sn", "<cmd>e ~/.config/nvim/my_snippets/<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>sn", ":lua require('telescope.builtin').find_files({prompt_title = '<~/.config/nvim/my_snippets/>', cwd = '~/.config/nvim/my_snippets/', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>sn", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~/.config/nvim/my_snippets/>', cwd = '~/.config/nvim/my_snippets/', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>sN", "<cmd>e ~/.config/nvim/my_snippets/luasnips<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>sN", ":lua require('telescope.builtin').find_files({prompt_title = '<~/.config/nvim/my_snippets/luasnips>', cwd = '~/.config/nvim/my_snippets/luasnips', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>sN", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~/.config/nvim/my_snippets/luasnips>', cwd = '~/.config/nvim/my_snippets/luasnips', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>vL", "<cmd>e ~/.config/nvim/lua/config/plugins/lsp/snippets<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>vL", ":lua require('telescope.builtin').find_files({prompt_title = '<~/.config/nvim/lua/config/plugins/lsp/snippets>', cwd = '~/.config/nvim/lua/config/plugins/lsp/snippets', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>vL", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~/.config/nvim/lua/config/plugins/lsp/snippets>', cwd = '~/.config/nvim/lua/config/plugins/lsp/snippets', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>m.", "<cmd>e /home/kanon/.local/share/scripts<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>m.", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/.local/share/scripts>', cwd = '/home/kanon/.local/share/scripts', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>m.", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/.local/share/scripts>', cwd = '/home/kanon/.local/share/scripts', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>ff", "<cmd>e /home/kanon/.local/share/scripts/files<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>ff", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/.local/share/scripts/files>', cwd = '/home/kanon/.local/share/scripts/files', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>ff", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/.local/share/scripts/files>', cwd = '/home/kanon/.local/share/scripts/files', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>u.", "<cmd>e /home/kanon/.local/share/scripts/utilities<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>u.", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/.local/share/scripts/utilities>', cwd = '/home/kanon/.local/share/scripts/utilities', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>u.", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/.local/share/scripts/utilities>', cwd = '/home/kanon/.local/share/scripts/utilities', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>a.", "<cmd>e /home/kanon/.local/share/scripts/automation<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>a.", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/.local/share/scripts/automation>', cwd = '/home/kanon/.local/share/scripts/automation', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>a.", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/.local/share/scripts/automation>', cwd = '/home/kanon/.local/share/scripts/automation', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>A.", "<cmd>e /home/kanon/.local/share/scripts/apps<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>A.", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/.local/share/scripts/apps>', cwd = '/home/kanon/.local/share/scripts/apps', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>A.", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/.local/share/scripts/apps>', cwd = '/home/kanon/.local/share/scripts/apps', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>o", "<cmd>e ~/Downloads<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>o", ":lua require('telescope.builtin').find_files({prompt_title = '<~/Downloads>', cwd = '~/Downloads', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>o", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~/Downloads>', cwd = '~/Downloads', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>O", "<cmd>e ~/Documents<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>O", ":lua require('telescope.builtin').find_files({prompt_title = '<~/Documents>', cwd = '~/Documents', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>O", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~/Documents>', cwd = '~/Documents', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>vv", "<cmd>e ~/Videos<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>vv", ":lua require('telescope.builtin').find_files({prompt_title = '<~/Videos>', cwd = '~/Videos', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>vv", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~/Videos>', cwd = '~/Videos', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>wa", "<cmd>e /home/kanon/Pictures/Wallpapers/all_time<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>wa", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/Pictures/Wallpapers/all_time>', cwd = '/home/kanon/Pictures/Wallpapers/all_time', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>wa", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/Pictures/Wallpapers/all_time>', cwd = '/home/kanon/Pictures/Wallpapers/all_time', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>wi", "<cmd>e /home/kanon/.local/share/wiki<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>wi", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/.local/share/wiki>', cwd = '/home/kanon/.local/share/wiki', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>wi", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/.local/share/wiki>', cwd = '/home/kanon/.local/share/wiki', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>win", "<cmd>e /home/kanon/.local/share/wiki/notes<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>win", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/.local/share/wiki/notes>', cwd = '/home/kanon/.local/share/wiki/notes', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>win", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/.local/share/wiki/notes>', cwd = '/home/kanon/.local/share/wiki/notes', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>wip", "<cmd>e /home/kanon/.local/share/wiki/personal<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>wip", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/.local/share/wiki/personal>', cwd = '/home/kanon/.local/share/wiki/personal', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>wip", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/.local/share/wiki/personal>', cwd = '/home/kanon/.local/share/wiki/personal', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>wicv", "<cmd>e /home/kanon/.local/share/wiki/personal/cv/latex<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>wicv", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/.local/share/wiki/personal/cv/latex>', cwd = '/home/kanon/.local/share/wiki/personal/cv/latex', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>wicv", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/.local/share/wiki/personal/cv/latex>', cwd = '/home/kanon/.local/share/wiki/personal/cv/latex', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>wS", "<cmd>e /home/kanon/.local/share/wiki/cheatsheets<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>wS", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/.local/share/wiki/cheatsheets>', cwd = '/home/kanon/.local/share/wiki/cheatsheets', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>wS", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/.local/share/wiki/cheatsheets>', cwd = '/home/kanon/.local/share/wiki/cheatsheets', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>mm", "<cmd>e ~/Music<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>mm", ":lua require('telescope.builtin').find_files({prompt_title = '<~/Music>', cwd = '~/Music', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>mm", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~/Music>', cwd = '~/Music', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>ca", "<cmd>e ~/.cache<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>ca", ":lua require('telescope.builtin').find_files({prompt_title = '<~/.cache>', cwd = '~/.cache', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>ca", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~/.cache>', cwd = '~/.cache', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>loo", "<cmd>e ~/.local<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>loo", ":lua require('telescope.builtin').find_files({prompt_title = '<~/.local>', cwd = '~/.local', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>loo", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~/.local>', cwd = '~/.local', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>los", "<cmd>e ~/.local/share<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>los", ":lua require('telescope.builtin').find_files({prompt_title = '<~/.local/share>', cwd = '~/.local/share', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>los", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~/.local/share>', cwd = '~/.local/share', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>lon", "<cmd>e ~/.local/share/nvim<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>lon", ":lua require('telescope.builtin').find_files({prompt_title = '<~/.local/share/nvim>', cwd = '~/.local/share/nvim', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>lon", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~/.local/share/nvim>', cwd = '~/.local/share/nvim', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>lol", "<cmd>e ~/.local/share/nvim/lazy<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>lol", ":lua require('telescope.builtin').find_files({prompt_title = '<~/.local/share/nvim/lazy>', cwd = '~/.local/share/nvim/lazy', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>lol", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~/.local/share/nvim/lazy>', cwd = '~/.local/share/nvim/lazy', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>lom", "<cmd>e ~/.local/share/nvim/mason<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>lom", ":lua require('telescope.builtin').find_files({prompt_title = '<~/.local/share/nvim/mason>', cwd = '~/.local/share/nvim/mason', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>lom", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~/.local/share/nvim/mason>', cwd = '~/.local/share/nvim/mason', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>lob", "<cmd>e ~/.local/bin<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>lob", ":lua require('telescope.builtin').find_files({prompt_title = '<~/.local/bin>', cwd = '~/.local/bin', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>lob", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~/.local/bin>', cwd = '~/.local/bin', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>Re", "<cmd>e /etc<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>Re", ":lua require('telescope.builtin').find_files({prompt_title = '</etc>', cwd = '/etc', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>Re", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /etc>', cwd = '/etc', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>RU", "<cmd>e /usr<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>RU", ":lua require('telescope.builtin').find_files({prompt_title = '</usr>', cwd = '/usr', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>RU", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /usr>', cwd = '/usr', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>Rus", "<cmd>e /usr/share<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>Rus", ":lua require('telescope.builtin').find_files({prompt_title = '</usr/share>', cwd = '/usr/share', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>Rus", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /usr/share>', cwd = '/usr/share', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>Rub", "<cmd>e /usr/bin<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>Rub", ":lua require('telescope.builtin').find_files({prompt_title = '</usr/bin>', cwd = '/usr/bin', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>Rub", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /usr/bin>', cwd = '/usr/bin', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>Rui", "<cmd>e /usr/include<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>Rui", ":lua require('telescope.builtin').find_files({prompt_title = '</usr/include>', cwd = '/usr/include', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>Rui", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /usr/include>', cwd = '/usr/include', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>Rulo", "<cmd>e /usr/local<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>Rulo", ":lua require('telescope.builtin').find_files({prompt_title = '</usr/local>', cwd = '/usr/local', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>Rulo", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /usr/local>', cwd = '/usr/local', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>Rulob", "<cmd>e /usr/local/bin<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>Rulob", ":lua require('telescope.builtin').find_files({prompt_title = '</usr/local/bin>', cwd = '/usr/local/bin', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>Rulob", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /usr/local/bin>', cwd = '/usr/local/bin', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>Rulos", "<cmd>e /usr/local/share<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>Rulos", ":lua require('telescope.builtin').find_files({prompt_title = '</usr/local/share>', cwd = '/usr/local/share', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>Rulos", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /usr/local/share>', cwd = '/usr/local/share', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>Ruloi", "<cmd>e /usr/local/include<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>Ruloi", ":lua require('telescope.builtin').find_files({prompt_title = '</usr/local/include>', cwd = '/usr/local/include', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>Ruloi", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /usr/local/include>', cwd = '/usr/local/include', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>Ruli", "<cmd>e /usr/lib<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>Ruli", ":lua require('telescope.builtin').find_files({prompt_title = '</usr/lib>', cwd = '/usr/lib', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>Ruli", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /usr/lib>', cwd = '/usr/lib', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>ex.", "<cmd>e /opt/exploitdb/exploits<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>ex.", ":lua require('telescope.builtin').find_files({prompt_title = '</opt/exploitdb/exploits>', cwd = '/opt/exploitdb/exploits', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>ex.", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /opt/exploitdb/exploits>', cwd = '/opt/exploitdb/exploits', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>Rv", "<cmd>e /var<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>Rv", ":lua require('telescope.builtin').find_files({prompt_title = '</var>', cwd = '/var', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>Rv", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /var>', cwd = '/var', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>Rb", "<cmd>e /bin<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>Rb", ":lua require('telescope.builtin').find_files({prompt_title = '</bin>', cwd = '/bin', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>Rb", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /bin>', cwd = '/bin', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>Rr", "<cmd>e /root<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>Rr", ":lua require('telescope.builtin').find_files({prompt_title = '</root>', cwd = '/root', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>Rr", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /root>', cwd = '/root', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>Ro", "<cmd>e /opt<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>Ro", ":lua require('telescope.builtin').find_files({prompt_title = '</opt>', cwd = '/opt', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>Ro", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /opt>', cwd = '/opt', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>Rmn", "<cmd>e /mnt<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>Rmn", ":lua require('telescope.builtin').find_files({prompt_title = '</mnt>', cwd = '/mnt', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>Rmn", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /mnt>', cwd = '/mnt', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>sc", "<cmd>e ~/Pictures/screenshots<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>sc", ":lua require('telescope.builtin').find_files({prompt_title = '<~/Pictures/screenshots>', cwd = '~/Pictures/screenshots', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>sc", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~/Pictures/screenshots>', cwd = '~/Pictures/screenshots', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>vo", "<cmd>e /home/kanon/volumes<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>vo", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/volumes>', cwd = '/home/kanon/volumes', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>vo", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/volumes>', cwd = '/home/kanon/volumes', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>an.", "<cmd>e ~/.local/share/ansible<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>an.", ":lua require('telescope.builtin').find_files({prompt_title = '<~/.local/share/ansible>', cwd = '~/.local/share/ansible', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>an.", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~/.local/share/ansible>', cwd = '~/.local/share/ansible', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>P", "<cmd>e /home/kanon/programs/<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>P", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/programs/>', cwd = '/home/kanon/programs/', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>P", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/programs/>', cwd = '/home/kanon/programs/', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>P.", "<cmd>e /home/kanon/programs/<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>P.", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/programs/>', cwd = '/home/kanon/programs/', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>P.", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/programs/>', cwd = '/home/kanon/programs/', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>p", "<cmd>e /home/kanon/projects/<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>p", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/projects/>', cwd = '/home/kanon/projects/', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>p", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/projects/>', cwd = '/home/kanon/projects/', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>p.", "<cmd>e /home/kanon/projects/<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>p.", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/projects/>', cwd = '/home/kanon/projects/', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>p.", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/projects/>', cwd = '/home/kanon/projects/', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>co.", "<cmd>e /home/kanon/code<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>co.", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/code>', cwd = '/home/kanon/code', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>co.", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/code>', cwd = '/home/kanon/code', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>c.", "<cmd>e ./.claude<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>c.", ":lua require('telescope.builtin').find_files({prompt_title = '<./.claude>', cwd = './.claude', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>c.", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ./.claude>', cwd = './.claude', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>cs.", "<cmd>e ./.claude/skills<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>cs.", ":lua require('telescope.builtin').find_files({prompt_title = '<./.claude/skills>', cwd = './.claude/skills', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>cs.", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ./.claude/skills>', cwd = './.claude/skills', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>pp", "<cmd>e ~/Pictures<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>pp", ":lua require('telescope.builtin').find_files({prompt_title = '<~/Pictures>', cwd = '~/Pictures', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>pp", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~/Pictures>', cwd = '~/Pictures', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>xm.", "<cmd>e ~/.config/xmonad<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>xm.", ":lua require('telescope.builtin').find_files({prompt_title = '<~/.config/xmonad>', cwd = '~/.config/xmonad', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>xm.", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~/.config/xmonad>', cwd = '~/.config/xmonad', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>k.", "<cmd>e /home/kanon/qmk_firmware<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>k.", ":lua require('telescope.builtin').find_files({prompt_title = '</home/kanon/qmk_firmware>', cwd = '/home/kanon/qmk_firmware', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>k.", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /home/kanon/qmk_firmware>', cwd = '/home/kanon/qmk_firmware', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>cl.", "<cmd>e ./.claude/lazy<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<backspace><a-p>cl.", ":lua require('telescope.builtin').find_files({prompt_title = '<./.claude/lazy>', cwd = './.claude/lazy', hidden = 'true'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<backspace><a-r>cl.", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ./.claude/lazy>', cwd = './.claude/lazy', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<backspace>.sf", "<cmd>e ~/.config/shortcuts/sf <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.sd", "<cmd>e ~/.config/shortcuts/sd <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.z", "<cmd>e ~/.config/zsh/.zshrc <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.ze", "<cmd>e ~/.config/zsh/.zshenv <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.zz", "<cmd>e ~/.config/zsh/.zshrc <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.zp", "<cmd>e ~/.config/zsh/.zprofile <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.pi", "<cmd>e ~/.config/picom/picom.conf <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.r", "<cmd>e ~/.config/ranger/rc.conf <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.lf", "<cmd>e ~/.config/lf/lfrc <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.b", "<cmd>e ~/.bashrc <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.xr", "<cmd>e ~/.Xresources <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.x", "<cmd>e ~/.xprofile <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.t", "<cmd>e ~/.config/tmux/tmux.conf <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.v", "<cmd>e ~/.config/nvim/init.lua <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.vw", "<cmd>e ~/.config/nvim/lua/work.lua <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.la", "<cmd>e .vscode/launch.json <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.vv", "<cmd>e ~/.config/nvim/init.lua <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.vA", "<cmd>e ~/.config/nvim/lua/config/automation/init.lua <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.va", "<cmd>e ~/.config/nvim/lua/ui/init.lua <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.vs", "<cmd>e ~/.config/nvim/lua/config/settings.lua <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.vu", "<cmd>e ~/.config/nvim/lua/utils/lua/telescope.lua <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.vk", "<cmd>e ~/.config/nvim/lua/keybindings/init.lua <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.vt", "<cmd>e ~/.config/nvim/lua/plugins/telescope.lua <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.vh", "<cmd>e ~/.config/nvim/lua/config/plugins/harpoon.lua <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.vK", "<cmd>e ~/.config/nvim/lua/keybindings/dap.lua <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.vd", "<cmd>e ~/.config/nvim/lua/config/plugins/dap/dap.lua <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.vl", "<cmd>e ~/.config/nvim/lua/config/plugins/lsp/lsp.lua <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.vL", "<cmd>e ~/.config/nvim/lua/config/plugins/lsp/lang_opts.lua <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.vp", "<cmd>e ~/.config/nvim/lua/plugins.lua <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.vf", "<cmd>e ~/.config/nvim/lua/config/plugins/lsp/formatters.lua <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.X", "<cmd>e ~/.config/sxhkd/sxhkdrc <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.A", "<cmd>e ~/.config/awesome/rc.lua <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.xm", "<cmd>e ~/.config/xmonad/xmonad.hs <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.xmm", "<cmd>e ~/.config/xmonad/xmonad.hs <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.xmb", "<cmd>e ~/.config/xmobar/xmobar0.hs <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.n", "<cmd>e ~/.config/newsboat/urls <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.dwm", "<cmd>e /home/kanon/programs/suckless/dwm/config.h <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.st", "<cmd>e /home/kanon/programs/suckless/st/config.h <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.a", "<cmd>e ~/.config/.aliases <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.aa", "<cmd>e ~/.config/.aliases <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.aw", "<cmd>e ~/.config/.aliases_work <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.su", "<cmd>e /home/kanon/.local/share/scripts/automation/startup/startup <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.sw", "<cmd>e ~/.config/.startup_work <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.sng", "<cmd>e ~/.config/nvim/my_snippets/snipmate/go.snippets <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.snl", "<cmd>e ~/.config/nvim/my_snippets/snipmate/lua.snippets <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.snp", "<cmd>e ~/.config/nvim/my_snippets/snipmate/python.snippets <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.ao", "<cmd>e ~/.config/zsh/.aliases <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.k", "<cmd>e /home/kanon/qmk_firmware/keyboards/lily58/keymaps/mine/keymap.c <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.K", "<cmd>e /home/kanon/.local/share/scripts/apps/zmk/mine/adv360.keymap <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.Z", "<cmd>e /root/.config/zsh/.zshrc <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.pr", "<cmd>e /home/kanon/.local/share/scripts/files/projections/global/.projections.json <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.s", "<cmd>e /home/kanon/.ssh/config <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.an", "<cmd>e ~/.local/share/ansible/local.yml <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.anc", "<cmd>e ~/.local/share/ansible/roles/core/tasks <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.anr", "<cmd>e ~/.local/share/ansible/README.md <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.ant", "<cmd>e ~/.local/share/ansible/tasks <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.anT", "<cmd>e ~/.local/share/ansible/TODO <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.y", "<cmd>e ~/.config/yazi/yazi.toml <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.cw", "<cmd>e ~/Pictures/current_wall <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.cs", "<cmd>e ~/.claude/settings.json <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<backspace>.c", "<cmd>e ~/CLAUDE.md <cr>", {silent=true, noremap=true})
