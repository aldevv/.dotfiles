version = "0.19.0"
-- add
local home = os.getenv("HOME")
local xpm_path = home .. "/.local/share/xplr/dtomvan/xpm.xplr"
local xpm_url = "https://github.com/dtomvan/xpm.xplr"
local xpm_paths = xpm_path .. "/?.lua;" .. xpm_path .. "/?/init.lua"

package.path = package.path .. ";" .. home .. "/.config/xplr/custom/?.lua;" .. xpm_paths

os.execute(string.format("[ -e '%s' ] || git clone '%s' '%s'", xpm_path, xpm_url, xpm_path))

require("plugins")
require("image_previewer")

-- require("plugins.image_previewer")

-- local home = os.getenv("HOME")

-- package.path = home
-- .. "/.config/xplr/plugins/?/init.lua;"
-- .. home .. "/.config/xplr/plugins/?.lua;"
-- .. package.path
--
-- require("icons").setup()
