-- Config { font = "xft:Roboto:size=8:bold"
-- Config { font = "xft:Noto Sans Emoji:pixelsize=11:antialias=true:autohint=true"
-- Config { font = "xft:DaddyTimeMono Nerd Font Mono:pixelsize=14:antialias=true:autohint=true:bold"
-- Config { font = "DaddyTimeMono Nerd Font Mono"
Config { font = "Noto Sans Emoji pixelsize 10"
       , additionalFonts =
       [
       "NotoColorEmoji pixelsize 10"
       , "JoyPixels pixelsize 10"
       , "monospace pixelsize 10"
       ]
          -- [ "xft:FontAwesome 6 Free Solid:pixelsize=10"
          -- , "xft:FontAwesome:pixelsize=10:bold"
          -- , "xft:FontAwesome 6 Free Solid:pixelsize=10"
          -- , "xft:Hack Nerd Font Mono:pixelsize=10"
          -- , "xft:Hack Nerd Font Mono:pixelsize=10"
          -- ]
       , border = NoBorder
       , bgColor = "#2B2E37"
       , fgColor = "#cccccc"
       , alpha = 255
       , position = TopSize L 100 15
       , textOffset = 1
       , textOffsets = [ 0, 0 ]
       , lowerOnStart = True
       , overrideRedirect = True
       , allDesktops = True
       , persistent = False
       , hideOnStart = False
       , iconRoot = "/home/kanon/.config/xmobar/icons/"
       , commands =
         [ Run UnsafeXPropertyLog "_XMONAD_LOG_0"
         , Run XPropertyLog "_XMONAD_TRAYPAD"
         , Run Com ".config/xmobar/dates.sh" [] "date" 10
         , Run Com ".config/xmobar/time.sh" [] "time" 10
         , Run Memory ["-t","<usedratio>ラム"] 10
         -- , Run Memory ["-t","<fc=#AAC0F0><usedratio></fc>ラム"] 10
         , Run Com ".config/xmobar/cpu_temp.sh" [] "cpu" 10
         , Run Com ".config/xmobar/gpu_temp.sh" [] "gpu" 10
         , Run Com ".config/xmobar/available_updates.sh" [] "updates" 10
         , Run Com ".config/xmobar/volume.sh" [] "volume" 10
         , Run Com ".config/xmobar/battery.sh" [] "battery" 10
         , Run Com ".config/xmobar/bluetooth.sh" [] "bluetooth" 10 , Run Com "/home/kanon/.config/xmobar/wifi.sh" [] "network" 10 ]
       , sepChar = "%"
       , alignSep = "}{"
       , template = "\
            \%_XMONAD_LOG_0%\
            \}\
            \{\
            \  \
            \%memory%\
            \  \
            \|\
            \  \
            \%volume%\
            \  \
            \|\
            \  \
            \%battery%\
            \  \
            \|\
            \  \
            \%time%\
            \  \
            \|\
            \  \
            \<action=xdotool key super+r>%date%</action>"
