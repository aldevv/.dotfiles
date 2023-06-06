Config { font = "xft:Roboto:size=12:bold"
       , additionalFonts =
          [ "xft:FontAwesome 6 Free Solid:pixelsize=14"
          , "xft:FontAwesome:pixelsize=10:bold"
          , "xft:FontAwesome 6 Free Solid:pixelsize=16"
          , "xft:Hack Nerd Font Mono:pixelsize=21"
          , "xft:Hack Nerd Font Mono:pixelsize=25"
          ]
       , border = NoBorder
       , bgColor = "#2B2E37"
       , fgColor = "#929AAD"
       , alpha = 255
       , position = TopSize L 100 15
       , textOffset = 1
       , textOffsets = [ 25, 24 ]
       , lowerOnStart = True
       , overrideRedirect = True
       , allDesktops = True
       , persistent = False
       , hideOnStart = False
       , iconRoot = "/home/kanon/.config/xmobar/icons/"
       , commands =
         [ Run UnsafeXPropertyLog "_XMONAD_LOG_1"
         , Run Date "%a, %d %b   <fn=1></fn>   %H:%M:%S" "date" 10
         , Run Memory ["-t","Mem: <fc=#AAC0F0><usedratio></fc>%"] 10
         , Run Com "/home/kanon/.config/xmobar/cpu_temp.sh" [] "cpu" 10
         , Run Com "/home/kanon/.config/xmobar/gpu_temp.sh" [] "gpu" 10
         , Run Com "/home/kanon/.config/xmobar/available_updates.sh" [] "updates" 10
         , Run Com "/home/kanon/.config/xmobar/volume.sh" [] "volume" 10
         , Run Com "/home/kanon/.config/xmobar/bluetooth.sh" [] "bluetooth" 10
         , Run Com "/home/kanon/.config/xmobar/wifi.sh" [] "network" 10
         , Run Com "/home/kanon/.config/xmobar/trayer-padding.sh" [] "trayerpad" 10
         ]
       , sepChar = "%"
       , alignSep = "}{"
       , template = "\
            \%_XMONAD_LOG_1%\
            \}\
            \<action=xdotool key super+r>%date%</action>\
            \{\
            \   \
            \%memory%\
            \   \
            \|\
            \   \
            \%cpu%"
       }
            -- \|\
            -- \   \
            -- \%gpu%"
