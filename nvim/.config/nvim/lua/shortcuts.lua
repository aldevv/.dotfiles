vim.keymap.set("n", "<localleader>H", "<cmd>e ~<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpH", ":lua require('telescope.builtin').find_files({prompt_title = '<~>', cwd = '~'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlH", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~>', cwd = '~', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>d.", "<cmd>e ~/.dotfiles<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpd.", ":lua require('telescope.builtin').find_files({prompt_title = '<~/.dotfiles>', cwd = '~/.dotfiles'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tld.", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~/.dotfiles>', cwd = '~/.dotfiles', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>uu", "<cmd>e $REMOTES<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpuu", ":lua require('telescope.builtin').find_files({prompt_title = '<$REMOTES>', cwd = '$REMOTES'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tluu", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP $REMOTES>', cwd = '$REMOTES', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>rr", "<cmd>e ~/repos<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tprr", ":lua require('telescope.builtin').find_files({prompt_title = '<~/repos>', cwd = '~/repos'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlrr", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~/repos>', cwd = '~/repos', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>n.", "<cmd>e $NOTES<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpn.", ":lua require('telescope.builtin').find_files({prompt_title = '<$NOTES>', cwd = '$NOTES'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tln.", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP $NOTES>', cwd = '$NOTES', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>N.", "<cmd>e $ATOMIC<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpN.", ":lua require('telescope.builtin').find_files({prompt_title = '<$ATOMIC>', cwd = '$ATOMIC'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlN.", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP $ATOMIC>', cwd = '$ATOMIC', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>wo", "<cmd>e $WORK<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpwo", ":lua require('telescope.builtin').find_files({prompt_title = '<$WORK>', cwd = '$WORK'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlwo", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP $WORK>', cwd = '$WORK', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>bk", "<cmd>e $BOOKS<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpbk", ":lua require('telescope.builtin').find_files({prompt_title = '<$BOOKS>', cwd = '$BOOKS'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlbk", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP $BOOKS>', cwd = '$BOOKS', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>bK", "<cmd>e $BOOKS/ln<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpbK", ":lua require('telescope.builtin').find_files({prompt_title = '<$BOOKS/ln>', cwd = '$BOOKS/ln'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlbK", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP $BOOKS/ln>', cwd = '$BOOKS/ln', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>ba", "<cmd>e $BACKUPS<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpba", ":lua require('telescope.builtin').find_files({prompt_title = '<$BACKUPS>', cwd = '$BACKUPS'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlba", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP $BACKUPS>', cwd = '$BACKUPS', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>ll", "<cmd>e $LEARN<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpll", ":lua require('telescope.builtin').find_files({prompt_title = '<$LEARN>', cwd = '$LEARN'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlll", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP $LEARN>', cwd = '$LEARN', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>l.", "<cmd>e $LEARN<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpl.", ":lua require('telescope.builtin').find_files({prompt_title = '<$LEARN>', cwd = '$LEARN'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tll.", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP $LEARN>', cwd = '$LEARN', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>T.", "<cmd>e $TRASH<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpT.", ":lua require('telescope.builtin').find_files({prompt_title = '<$TRASH>', cwd = '$TRASH'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlT.", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP $TRASH>', cwd = '$TRASH', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>Tt", "<cmd>e $TRASH<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpTt", ":lua require('telescope.builtin').find_files({prompt_title = '<$TRASH>', cwd = '$TRASH'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlTt", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP $TRASH>', cwd = '$TRASH', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>Tr", "<cmd>e $HOME/Downloads/torrents<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpTr", ":lua require('telescope.builtin').find_files({prompt_title = '<$HOME/Downloads/torrents>', cwd = '$HOME/Downloads/torrents'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlTr", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP $HOME/Downloads/torrents>', cwd = '$HOME/Downloads/torrents', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>sk", "<cmd>e $SUCKLESS<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpsk", ":lua require('telescope.builtin').find_files({prompt_title = '<$SUCKLESS>', cwd = '$SUCKLESS'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlsk", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP $SUCKLESS>', cwd = '$SUCKLESS', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>f.", "<cmd>e $XDG_CONFIG_HOME<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpf.", ":lua require('telescope.builtin').find_files({prompt_title = '<$XDG_CONFIG_HOME>', cwd = '$XDG_CONFIG_HOME'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlf.", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP $XDG_CONFIG_HOME>', cwd = '$XDG_CONFIG_HOME', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>v.", "<cmd>e $XDG_CONFIG_HOME/nvim<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpv.", ":lua require('telescope.builtin').find_files({prompt_title = '<$XDG_CONFIG_HOME/nvim>', cwd = '$XDG_CONFIG_HOME/nvim'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlv.", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP $XDG_CONFIG_HOME/nvim>', cwd = '$XDG_CONFIG_HOME/nvim', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>vl", "<cmd>e $XDG_CONFIG_HOME/nvim/lua/lsp<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpvl", ":lua require('telescope.builtin').find_files({prompt_title = '<$XDG_CONFIG_HOME/nvim/lua/lsp>', cwd = '$XDG_CONFIG_HOME/nvim/lua/lsp'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlvl", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP $XDG_CONFIG_HOME/nvim/lua/lsp>', cwd = '$XDG_CONFIG_HOME/nvim/lua/lsp', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>va", "<cmd>e $XDG_CONFIG_HOME/nvim/lua/config/automation<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpva", ":lua require('telescope.builtin').find_files({prompt_title = '<$XDG_CONFIG_HOME/nvim/lua/config/automation>', cwd = '$XDG_CONFIG_HOME/nvim/lua/config/automation'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlva", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP $XDG_CONFIG_HOME/nvim/lua/config/automation>', cwd = '$XDG_CONFIG_HOME/nvim/lua/config/automation', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>vt", "<cmd>e $XDG_CONFIG_HOME/nvim/lua/config/appearance/themes<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpvt", ":lua require('telescope.builtin').find_files({prompt_title = '<$XDG_CONFIG_HOME/nvim/lua/config/appearance/themes>', cwd = '$XDG_CONFIG_HOME/nvim/lua/config/appearance/themes'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlvt", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP $XDG_CONFIG_HOME/nvim/lua/config/appearance/themes>', cwd = '$XDG_CONFIG_HOME/nvim/lua/config/appearance/themes', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>vc", "<cmd>e $XDG_CONFIG_HOME/nvim/lua/core<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpvc", ":lua require('telescope.builtin').find_files({prompt_title = '<$XDG_CONFIG_HOME/nvim/lua/core>', cwd = '$XDG_CONFIG_HOME/nvim/lua/core'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlvc", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP $XDG_CONFIG_HOME/nvim/lua/core>', cwd = '$XDG_CONFIG_HOME/nvim/lua/core', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>vC", "<cmd>e $XDG_CONFIG_HOME/nvim/lua/config<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpvC", ":lua require('telescope.builtin').find_files({prompt_title = '<$XDG_CONFIG_HOME/nvim/lua/config>', cwd = '$XDG_CONFIG_HOME/nvim/lua/config'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlvC", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP $XDG_CONFIG_HOME/nvim/lua/config>', cwd = '$XDG_CONFIG_HOME/nvim/lua/config', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>vu", "<cmd>e $XDG_CONFIG_HOME/nvim/lua/utils<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpvu", ":lua require('telescope.builtin').find_files({prompt_title = '<$XDG_CONFIG_HOME/nvim/lua/utils>', cwd = '$XDG_CONFIG_HOME/nvim/lua/utils'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlvu", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP $XDG_CONFIG_HOME/nvim/lua/utils>', cwd = '$XDG_CONFIG_HOME/nvim/lua/utils', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>vk", "<cmd>e $XDG_CONFIG_HOME/nvim/lua/config/keybindings<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpvk", ":lua require('telescope.builtin').find_files({prompt_title = '<$XDG_CONFIG_HOME/nvim/lua/config/keybindings>', cwd = '$XDG_CONFIG_HOME/nvim/lua/config/keybindings'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlvk", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP $XDG_CONFIG_HOME/nvim/lua/config/keybindings>', cwd = '$XDG_CONFIG_HOME/nvim/lua/config/keybindings', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>sn", "<cmd>e ~/.config/nvim/my_snippets/snipmate/<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpsn", ":lua require('telescope.builtin').find_files({prompt_title = '<~/.config/nvim/my_snippets/snipmate/>', cwd = '~/.config/nvim/my_snippets/snipmate/'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlsn", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~/.config/nvim/my_snippets/snipmate/>', cwd = '~/.config/nvim/my_snippets/snipmate/', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>sN", "<cmd>e ~/.config/nvim/my_snippets/luasnips<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpsN", ":lua require('telescope.builtin').find_files({prompt_title = '<~/.config/nvim/my_snippets/luasnips>', cwd = '~/.config/nvim/my_snippets/luasnips'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlsN", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~/.config/nvim/my_snippets/luasnips>', cwd = '~/.config/nvim/my_snippets/luasnips', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>vL", "<cmd>e ~/.config/nvim/lua/lsp/snippets<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpvL", ":lua require('telescope.builtin').find_files({prompt_title = '<~/.config/nvim/lua/lsp/snippets>', cwd = '~/.config/nvim/lua/lsp/snippets'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlvL", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~/.config/nvim/lua/lsp/snippets>', cwd = '~/.config/nvim/lua/lsp/snippets', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>m.", "<cmd>e $SCRIPTS<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpm.", ":lua require('telescope.builtin').find_files({prompt_title = '<$SCRIPTS>', cwd = '$SCRIPTS'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlm.", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP $SCRIPTS>', cwd = '$SCRIPTS', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>ff", "<cmd>e $FILES<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpff", ":lua require('telescope.builtin').find_files({prompt_title = '<$FILES>', cwd = '$FILES'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlff", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP $FILES>', cwd = '$FILES', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>u.", "<cmd>e $UTILITIES<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpu.", ":lua require('telescope.builtin').find_files({prompt_title = '<$UTILITIES>', cwd = '$UTILITIES'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlu.", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP $UTILITIES>', cwd = '$UTILITIES', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>a.", "<cmd>e $AUTOMATION<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpa.", ":lua require('telescope.builtin').find_files({prompt_title = '<$AUTOMATION>', cwd = '$AUTOMATION'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tla.", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP $AUTOMATION>', cwd = '$AUTOMATION', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>A.", "<cmd>e $APPS<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpA.", ":lua require('telescope.builtin').find_files({prompt_title = '<$APPS>', cwd = '$APPS'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlA.", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP $APPS>', cwd = '$APPS', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>ml.", "<cmd>e $MLIBS<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpml.", ":lua require('telescope.builtin').find_files({prompt_title = '<$MLIBS>', cwd = '$MLIBS'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlml.", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP $MLIBS>', cwd = '$MLIBS', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>O", "<cmd>e ~/Downloads<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpO", ":lua require('telescope.builtin').find_files({prompt_title = '<~/Downloads>', cwd = '~/Downloads'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlO", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~/Downloads>', cwd = '~/Downloads', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>o", "<cmd>e ~/Documents<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpo", ":lua require('telescope.builtin').find_files({prompt_title = '<~/Documents>', cwd = '~/Documents'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlo", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~/Documents>', cwd = '~/Documents', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>vv", "<cmd>e ~/Videos<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpvv", ":lua require('telescope.builtin').find_files({prompt_title = '<~/Videos>', cwd = '~/Videos'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlvv", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~/Videos>', cwd = '~/Videos', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>wa", "<cmd>e $WALL<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpwa", ":lua require('telescope.builtin').find_files({prompt_title = '<$WALL>', cwd = '$WALL'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlwa", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP $WALL>', cwd = '$WALL', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>wi", "<cmd>e $WIKI<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpwi", ":lua require('telescope.builtin').find_files({prompt_title = '<$WIKI>', cwd = '$WIKI'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlwi", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP $WIKI>', cwd = '$WIKI', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>wp", "<cmd>e $WIKI/personal<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpwp", ":lua require('telescope.builtin').find_files({prompt_title = '<$WIKI/personal>', cwd = '$WIKI/personal'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlwp", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP $WIKI/personal>', cwd = '$WIKI/personal', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>wS", "<cmd>e $WIKI/cheatsheets<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpwS", ":lua require('telescope.builtin').find_files({prompt_title = '<$WIKI/cheatsheets>', cwd = '$WIKI/cheatsheets'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlwS", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP $WIKI/cheatsheets>', cwd = '$WIKI/cheatsheets', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>mm", "<cmd>e ~/Music<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpmm", ":lua require('telescope.builtin').find_files({prompt_title = '<~/Music>', cwd = '~/Music'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlmm", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~/Music>', cwd = '~/Music', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>ca", "<cmd>e ~/.cache<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpca", ":lua require('telescope.builtin').find_files({prompt_title = '<~/.cache>', cwd = '~/.cache'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlca", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~/.cache>', cwd = '~/.cache', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>loo", "<cmd>e ~/.local<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tploo", ":lua require('telescope.builtin').find_files({prompt_title = '<~/.local>', cwd = '~/.local'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlloo", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~/.local>', cwd = '~/.local', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>los", "<cmd>e ~/.local/share<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tplos", ":lua require('telescope.builtin').find_files({prompt_title = '<~/.local/share>', cwd = '~/.local/share'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tllos", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~/.local/share>', cwd = '~/.local/share', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>lon", "<cmd>e ~/.local/share/nvim<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tplon", ":lua require('telescope.builtin').find_files({prompt_title = '<~/.local/share/nvim>', cwd = '~/.local/share/nvim'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tllon", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~/.local/share/nvim>', cwd = '~/.local/share/nvim', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>lol", "<cmd>e ~/.local/share/nvim/lazy<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tplol", ":lua require('telescope.builtin').find_files({prompt_title = '<~/.local/share/nvim/lazy>', cwd = '~/.local/share/nvim/lazy'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tllol", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~/.local/share/nvim/lazy>', cwd = '~/.local/share/nvim/lazy', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>lom", "<cmd>e ~/.local/share/nvim/mason<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tplom", ":lua require('telescope.builtin').find_files({prompt_title = '<~/.local/share/nvim/mason>', cwd = '~/.local/share/nvim/mason'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tllom", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~/.local/share/nvim/mason>', cwd = '~/.local/share/nvim/mason', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>lob", "<cmd>e ~/.local/bin<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tplob", ":lua require('telescope.builtin').find_files({prompt_title = '<~/.local/bin>', cwd = '~/.local/bin'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tllob", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~/.local/bin>', cwd = '~/.local/bin', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>Re", "<cmd>e /etc<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpRe", ":lua require('telescope.builtin').find_files({prompt_title = '</etc>', cwd = '/etc'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlRe", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /etc>', cwd = '/etc', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>RU", "<cmd>e /usr<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpRU", ":lua require('telescope.builtin').find_files({prompt_title = '</usr>', cwd = '/usr'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlRU", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /usr>', cwd = '/usr', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>Rus", "<cmd>e /usr/share<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpRus", ":lua require('telescope.builtin').find_files({prompt_title = '</usr/share>', cwd = '/usr/share'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlRus", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /usr/share>', cwd = '/usr/share', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>Rub", "<cmd>e /usr/bin<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpRub", ":lua require('telescope.builtin').find_files({prompt_title = '</usr/bin>', cwd = '/usr/bin'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlRub", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /usr/bin>', cwd = '/usr/bin', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>Rui", "<cmd>e /usr/include<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpRui", ":lua require('telescope.builtin').find_files({prompt_title = '</usr/include>', cwd = '/usr/include'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlRui", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /usr/include>', cwd = '/usr/include', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>Rulo", "<cmd>e /usr/local<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpRulo", ":lua require('telescope.builtin').find_files({prompt_title = '</usr/local>', cwd = '/usr/local'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlRulo", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /usr/local>', cwd = '/usr/local', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>Rulob", "<cmd>e /usr/local/bin<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpRulob", ":lua require('telescope.builtin').find_files({prompt_title = '</usr/local/bin>', cwd = '/usr/local/bin'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlRulob", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /usr/local/bin>', cwd = '/usr/local/bin', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>Rulos", "<cmd>e /usr/local/share<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpRulos", ":lua require('telescope.builtin').find_files({prompt_title = '</usr/local/share>', cwd = '/usr/local/share'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlRulos", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /usr/local/share>', cwd = '/usr/local/share', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>Ruloi", "<cmd>e /usr/local/include<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpRuloi", ":lua require('telescope.builtin').find_files({prompt_title = '</usr/local/include>', cwd = '/usr/local/include'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlRuloi", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /usr/local/include>', cwd = '/usr/local/include', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>Ruli", "<cmd>e /usr/lib<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpRuli", ":lua require('telescope.builtin').find_files({prompt_title = '</usr/lib>', cwd = '/usr/lib'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlRuli", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /usr/lib>', cwd = '/usr/lib', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>ex.", "<cmd>e /opt/exploitdb/exploits<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpex.", ":lua require('telescope.builtin').find_files({prompt_title = '</opt/exploitdb/exploits>', cwd = '/opt/exploitdb/exploits'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlex.", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /opt/exploitdb/exploits>', cwd = '/opt/exploitdb/exploits', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>Rv", "<cmd>e /var<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpRv", ":lua require('telescope.builtin').find_files({prompt_title = '</var>', cwd = '/var'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlRv", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /var>', cwd = '/var', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>Rb", "<cmd>e /bin<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpRb", ":lua require('telescope.builtin').find_files({prompt_title = '</bin>', cwd = '/bin'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlRb", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /bin>', cwd = '/bin', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>Rr", "<cmd>e /root<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpRr", ":lua require('telescope.builtin').find_files({prompt_title = '</root>', cwd = '/root'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlRr", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /root>', cwd = '/root', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>Ro", "<cmd>e /opt<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpRo", ":lua require('telescope.builtin').find_files({prompt_title = '</opt>', cwd = '/opt'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlRo", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /opt>', cwd = '/opt', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>Rmn", "<cmd>e /mnt<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpRmn", ":lua require('telescope.builtin').find_files({prompt_title = '</mnt>', cwd = '/mnt'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlRmn", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP /mnt>', cwd = '/mnt', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>sc", "<cmd>e ~/Pictures/screenshots<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpsc", ":lua require('telescope.builtin').find_files({prompt_title = '<~/Pictures/screenshots>', cwd = '~/Pictures/screenshots'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlsc", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~/Pictures/screenshots>', cwd = '~/Pictures/screenshots', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>vo", "<cmd>e $VOLUMES<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpvo", ":lua require('telescope.builtin').find_files({prompt_title = '<$VOLUMES>', cwd = '$VOLUMES'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlvo", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP $VOLUMES>', cwd = '$VOLUMES', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>an.", "<cmd>e ~/.local/share/ansible<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpan.", ":lua require('telescope.builtin').find_files({prompt_title = '<~/.local/share/ansible>', cwd = '~/.local/share/ansible'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlan.", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~/.local/share/ansible>', cwd = '~/.local/share/ansible', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>P", "<cmd>e $PROGRAMS/<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpP", ":lua require('telescope.builtin').find_files({prompt_title = '<$PROGRAMS/>', cwd = '$PROGRAMS/'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlP", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP $PROGRAMS/>', cwd = '$PROGRAMS/', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>P.", "<cmd>e $PROGRAMS/<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpP.", ":lua require('telescope.builtin').find_files({prompt_title = '<$PROGRAMS/>', cwd = '$PROGRAMS/'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlP.", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP $PROGRAMS/>', cwd = '$PROGRAMS/', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>p", "<cmd>e $PROJECTS/<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpp", ":lua require('telescope.builtin').find_files({prompt_title = '<$PROJECTS/>', cwd = '$PROJECTS/'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlp", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP $PROJECTS/>', cwd = '$PROJECTS/', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>p.", "<cmd>e $PROJECTS/<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpp.", ":lua require('telescope.builtin').find_files({prompt_title = '<$PROJECTS/>', cwd = '$PROJECTS/'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlp.", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP $PROJECTS/>', cwd = '$PROJECTS/', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>c.", "<cmd>e $CODE<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tpc.", ":lua require('telescope.builtin').find_files({prompt_title = '<$CODE>', cwd = '$CODE'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlc.", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP $CODE>', cwd = '$CODE', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>pp", "<cmd>e ~/Pictures<cr>", {silent=true, noremap=true})
vim.keymap.set("n","<localleader>tppp", ":lua require('telescope.builtin').find_files({prompt_title = '<~/Pictures>', cwd = '~/Pictures'})<cr>", { noremap = true, silent = true })
vim.keymap.set("n","<localleader>tlpp", ":lua require('telescope.builtin').grep_string({prompt_title = '<LIVE GREP ~/Pictures>', cwd = '~/Pictures', search ='',  shorten_path = true})<cr>", { noremap = true, silent = true })

vim.keymap.set("n", "<localleader>.sf", "<cmd>e ~/.config/shortcuts/sf <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.sd", "<cmd>e ~/.config/shortcuts/sd <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.z", "<cmd>e ~/.config/zsh/.zshrc <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.zz", "<cmd>e ~/.config/zsh/.zshrc <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.zp", "<cmd>e ~/.config/zsh/.zprofile <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.pi", "<cmd>e ~/.config/picom/picom.conf <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.r", "<cmd>e ~/.config/ranger/rc.conf <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.lf", "<cmd>e ~/.config/lf/lfrc <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.b", "<cmd>e ~/.bashrc <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.xr", "<cmd>e ~/.Xresources <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.x", "<cmd>e ~/.xprofile <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.t", "<cmd>e ~/.config/tmux/tmux.conf <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.v", "<cmd>e ~/.config/nvim/init.lua <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.vw", "<cmd>e ~/.config/nvim/lua/work.lua <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.la", "<cmd>e .vscode/launch.json <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.vv", "<cmd>e ~/.config/nvim/init.lua <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.va", "<cmd>e ~/.config/nvim/lua/config/automation/init.lua <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.vA", "<cmd>e ~/.config/nvim/lua/config/appearance/init.lua <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.vt", "<cmd>e ~/.config/nvim/lua/core/telescope.lua <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.vs", "<cmd>e ~/.config/nvim/lua/config/settings.lua <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.vu", "<cmd>e ~/.config/nvim/lua/utils/lua/telescope.lua <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.vk", "<cmd>e ~/.config/nvim/lua/config/keybindings/init.lua <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.vK", "<cmd>e ~/.config/nvim/lua/config/keybindings/dap.lua <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.vd", "<cmd>e ~/.config/nvim/lua/lsp/dap/dap.lua <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.vl", "<cmd>e ~/.config/nvim/lua/lsp/lsp.lua <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.vL", "<cmd>e ~/.config/nvim/lua/lsp/lang_opts.lua <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.vp", "<cmd>e ~/.config/nvim/lua/plugins.lua <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.vP", "<cmd>e ~/.config/nvim/lua/plugins-debug.lua <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.vf", "<cmd>e ~/.config/nvim/lua/lsp/formatters.lua <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.X", "<cmd>e ~/.config/sxhkd/sxhkdrc <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.A", "<cmd>e ~/.config/awesome/rc.lua <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.xm", "<cmd>e ~/.config/xmonad/xmonad.hs <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.xmm", "<cmd>e ~/.config/xmonad/xmonad.hs <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.xmb", "<cmd>e ~/.config/xmobar/xmobar0.hs <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.n", "<cmd>e ~/.config/newsboat/urls <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.dwm", "<cmd>e $SUCKLESS/dwm/config.h <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.st", "<cmd>e $SUCKLESS/st/config.h <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.a", "<cmd>e ~/.config/.aliases <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.aa", "<cmd>e ~/.config/.aliases <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.aw", "<cmd>e ~/.config/.aliases_work <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.sw", "<cmd>e ~/.config/.startup_work <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.ss", "<cmd>e $AUTOMATION/startup/startup <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.sng", "<cmd>e ~/.config/nvim/my_snippets/snipmate/go.snippets <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.snl", "<cmd>e ~/.config/nvim/my_snippets/snipmate/lua.snippets <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.snp", "<cmd>e ~/.config/nvim/my_snippets/snipmate/python.snippets <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.ao", "<cmd>e ~/.config/zsh/.aliases <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.k", "<cmd>e $HOME/qmk_firmware/keyboards/lily58/keymaps/mine/keymap.c <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.Z", "<cmd>e /root/.config/zsh/.zshrc <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.pr", "<cmd>e $FILES/projections/global/.projections.json <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.s", "<cmd>e $HOME/.ssh/config <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.an", "<cmd>e ~/.local/share/ansible/local.yml <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.anc", "<cmd>e ~/.local/share/ansible/roles/core/tasks <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.anr", "<cmd>e ~/.local/share/ansible/README.md <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.ant", "<cmd>e ~/.local/share/ansible/tasks <cr>", {silent=true, noremap=true})
vim.keymap.set("n", "<localleader>.anT", "<cmd>e ~/.local/share/ansible/TODO <cr>", {silent=true, noremap=true})
