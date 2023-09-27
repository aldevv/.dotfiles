-- if not finding magick rock do these
-- sudo luarocks install --server=https://luarocks.org/dev luaffi
-- sudo apt install libmagickwand-dev

-- Example for configuring Neovim to load user-installed installed Lua rocks:
package.path = package.path .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?/init.lua;"
package.path = package.path .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?.lua;"
require("image").setup({
  backend = "ueberzug",
  integrations = {
    markdown = {
      enabled = true,
      clear_in_insert_mode = false,
      download_remote_images = true,
      only_render_image_at_cursor = false,
      filetypes = { "markdown", "vimwiki" }, -- markdown extensions (ie. quarto) can go here
    },
    neorg = {
      enabled = true,
      clear_in_insert_mode = false,
      download_remote_images = true,
      only_render_image_at_cursor = false,
      filetypes = { "norg" },
    },
  },
  max_width = nil,
  max_height = nil,
  max_width_window_percentage = nil,
  max_height_window_percentage = 50,
  window_overlap_clear_enabled = false, -- toggles images when windows are overlapped
  window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
})
