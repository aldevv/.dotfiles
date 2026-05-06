#!/bin/bash
echo \
'#!/bin/bash

source /usr/share/defaults/etc/profile
source $HOME/.zprofile
source $HOME/.xprofile

exec $*' > /usr/bin/lightdm-wrapper
