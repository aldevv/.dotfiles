#!/usr/bin/env sh

# since the right port is broken, don't do the EE_HANDS options, just run this script

#if EE_HANDS enabled then use the following 2
# needed to flash with make lily58:mine-def:avrdude-split-left with only left side connected
# needed to flash with make lily58:mine-def:avrdude-split-right with only right side connected

pipenv shell
pip install qmk
git clone https://github.com/qmk/qmk_firmware
cd qmk_firmware
cp -r $APPS/qmk/lily58 ./qmk_firmware/keyboards/lily58/keymaps/mine
qmk setup
qmk compile -kb lily58 -km mine && qmk flash -kb lily58 -km mine"
