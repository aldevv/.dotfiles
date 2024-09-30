require("refactoring").setup({
  prompt_func_return_type = {
    go = false, -- default
  },
  prompt_func_param_type = {
    go = false, -- default
  },
  printf_statements = {
    cpp = {
      'std::cout << "%s" << std::endl;',
    },
    -- rs = {
    -- 	'println!("%s")',
    -- },
  },
  print_var_statements = {
    -- %% is to escape the %
    go = {
      'fmt.Println(fmt.Sprintf("%s %%+v", %s))',
    },
    cpp = {
      'printf("a custom statement %%s %s", %s)',
    },
    -- rs = {
    -- 	'println!("%s {}", %s)',
    -- },
  },
})

vim.g.printf_number = 0
function var_normal()
  vim.g.printf_number = vim.g.printf_number + 1
  vim.cmd([[normal! o// __AUTO_GENERATED_PRINTF_START__
normal! oprintln!("PRINT ]] .. vim.g.printf_number .. [["); // __AUTO_GENERATED_PRINTF_END__
normal! F"h]])
end

-- simple handlers for rust
vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = { "rust" },
  callback = function()
    vim.keymap.set("n", "R", var_normal, { desc = "Debug Printf" })
    vim.keymap.set("n", "<leader>rc", function()
      require("refactoring").debug.cleanup({})
      vim.g.printf_number = 0
    end, { desc = "Debug Cleanup" })

    vim.keymap.set(
      "n",
      "<leader>v",
      [[
"vyiwo// __AUTO_GENERATED_PRINTF_START__
println!("PRINT#VAR: <c-o>"vp {:?}", <c-o>"vp); // __AUTO_GENERATED_PRINTF_END__<esc>F{h]],
      { desc = "Debug Var Printf" }
    )
    vim.keymap.set(
      "v",
      "<leader>v",
      [[
"vyo// __AUTO_GENERATED_PRINTF_START__
println!("PRINT#VAR: <c-o>"vp {:?}", <c-o>"vp); // __AUTO_GENERATED_PRINTF_END__<esc>F"h]],
      { desc = "Debug Var Printf" }
    )
  end,
})

-- load refactoring Telescope extension
local ok, telescope = pcall(require, "telescope")
if not ok then
  return
end
telescope.load_extension("refactoring")
