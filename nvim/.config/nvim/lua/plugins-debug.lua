-- docs -> https://github.com/wbthomason/packer.nvim
--
-- install packer -> git clone --depth 1 https://github.com/wbthomason/packer.nvim ~/.local/share/nvim/site/pack/packer/start/packer.nvim

-- options
-- run = runs shell command on install/update
-- cmd = nvim commands made from plugin
-- branch = use specific branch
-- config = plugin's configuration

-- Local plugins can be included
-- use '~/projects/personal/hover.nvim'

local function req(module)
    return string.format('require("%s")', module)
end

return require("packer").startup({
    function(use)
        use("wbthomason/packer.nvim")
    end,
    config = {
        display = {
            open_fn = function()
                return require("packer.util").float({ border = "single" })
            end,
        },
    },
})
