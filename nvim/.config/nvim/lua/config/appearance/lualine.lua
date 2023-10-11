local filename_widget = {
  "filename",
  file_status = true,
  newfile_staus = true,
  path = 0,
  symbols = {
    modified = " ",
    readonly = " ",
    unnamed = "[No Name]",
    newfile = " ",
  },
}

local diagnostics_widget = {
  "diagnostics",
  sources = { "nvim_diagnostic" },
  sections = { "error", "warn", "info", "hint" },
  symbols = {
    error = " ",
    warn = " ",
    info = " ",
  },
}

local styles = {
  powerline = {
    section_separators = { left = "", right = "" },
    component_separators = { left = "", right = "" },
  },
  plain = {
    section_separators = { left = "", right = "" },
    component_separators = { left = "", right = "" },
  },
  plain_separators = {
    section_separators = { left = "", right = "" },
    component_separators = { left = "│", right = "│" },
  },
  slant_low = {
    section_separators = { left = "", right = "" },
    component_separators = { left = "", right = "" },
  },
  slant_high = {
    section_separators = { left = "", right = "" },
    component_separators = { left = "", right = "" },
  },
  round = {
    section_separators = { left = "", right = "" },
    component_separators = { left = "", right = "" },
  },
  pixel = {
    section_separators = { left = "", right = "" },
    component_separators = { left = "", right = "" },
  },
}

local style = styles["slant_low"]
require("lualine").setup({
  options = {
    icons_enabled = true,
    -- theme = 'gruvbox',
    theme = "auto",
    -- theme = "auto",
    -- component_separators = { left = "", right = "" },
    -- section_separators = { left = "", right = "" },
    component_separators = style.component_separators,
    section_separators = style.section_separators,
    disabled_filetypes = {},
    always_divide_middle = true,
    globalstatus = false,
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = { "branch", "diff", "diagnostics" },
    lualine_c = { { "filename", path = 1 } },
    lualine_x = { "filetype" },
    lualine_y = { "progress" },
    lualine_z = { "location" },
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = { { "filename", path = 1 } },
    lualine_x = { "location" },
    lualine_y = {},
    lualine_z = {},
  },
  tabline = {},
  extensions = {},
})
