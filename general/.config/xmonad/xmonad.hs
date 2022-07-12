import System.Exit
import XMonad
import XMonad.Actions.CycleWS
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.ManageHelpers (isDialog)
import XMonad.Hooks.StatusBar
import XMonad.Layout.Magnifier
import XMonad.Layout.ThreeColumns
import qualified XMonad.StackSet as W
import XMonad.Util.EZConfig
import XMonad.Util.Loggers

-- ewmhFullscreen lets apps know about the window size
main :: IO ()
main =
  xmonad
    . ewmhFullscreen
    . ewmh
    . withEasySB (statusBarProp "xmobar" (pure myXmobarPP)) toggleStrutsKey
    $ myConfig
  where
    toggleStrutsKey :: XConfig Layout -> (KeyMask, KeySym)
    toggleStrutsKey XConfig {modMask = m} = (m, xK_b)

myConfig =
  def
    { modMask = mod4Mask,
      terminal = "st",
      layoutHook = customLayout,
      manageHook = myManageHook
    }
    `additionalKeys` myKeysGranular
    `additionalKeysP` myKeys
    `removeKeysP` removeDefaultKeys

myKeysGranular =
  [ ((mod5Mask, xK_comma), swapNextScreen)
  ]

myKeys :: [(String, X ())]
myKeys =
  [ ("M-w", spawn "firefox"),
    ("M-R", spawn "nautilus"),
    ("M-r", spawn "st -e ranger"),
    ("M-q", kill),
    ("M-l", sendMessage NextLayout),
    ("M-S-t", withFocused $ windows . W.sink), -- retile window
    -- Quit xmonad
    ("M-S-q", io exitSuccess),
    ("M-c", spawn "~/.local/bin/xmonad --recompile; ~/.local/bin/xmonad --restart"),
    -----------
    -- MOVEMENT
    -----------
    ("M-n", windows W.focusDown),
    ("M-e", windows W.focusUp),
    ("M-h", sendMessage Shrink),
    ("M-i", sendMessage Expand),
    -- a basic CycleWS setup
    ("M-ñ", nextScreen), -- need to change promotion bindings
    ("M-S-ñ", shiftNextScreen)
    -- ("M-s-.", swapNextScreen) -- change to mode_switch

    -- , ("M-,",    prevWS)
  ]

removeDefaultKeys = ["M-t", "M-<Space>"]

customLayout = tiled ||| Mirror tiled ||| Full ||| threeCol
  where
    threeCol = magnifiercz 1.3 (ThreeColMid nmaster delta ratio)
    tiled = Tall nmaster delta ratio
    nmaster = 1 -- Default number of windows in the master pane
    ratio = 1 / 2 -- Default proportion of screen occupied by master pane
    delta = 3 / 100 -- Percent of screen to increment by when resizing panes

myXmobarPP :: PP
myXmobarPP =
  def
    { ppSep = magenta " • ",
      ppTitleSanitize = xmobarStrip,
      ppCurrent = wrap " " "" . xmobarBorder "Top" "#8be9fd" 2,
      ppHidden = white . wrap " " "",
      ppHiddenNoWindows = lowWhite . wrap " " "",
      ppUrgent = red . wrap (yellow "!") (yellow "!"),
      -- we ignore the third argument because wins already shows cur window!
      ppOrder = \[ws, l, _, wins] -> [ws, l, wins], -- > orders stuff in the xmobar (workspaces, layout, title of cur window, and wins, )
      ppExtras = [logTitles formatFocused formatUnfocused] -- > this becomes "wins" in pporder, if you add more extras, you would add one more to pporder
    }
  where
    -- myOrder [ws, l, _, wins] = [ws, l, wins]  here we could, but we used a lambda better
    formatFocused = wrap (white "[") (white "]") . magenta . ppWindow
    formatUnfocused = wrap (lowWhite "[") (lowWhite "]") . blue . ppWindow

    -- Windows should have *some* title, which should not not exceed a
    -- sane length.
    ppWindow :: String -> String
    ppWindow = xmobarRaw . (\w -> if null w then "untitled" else w) . shorten 30

    blue, lowWhite, magenta, red, white, yellow :: String -> String
    magenta = xmobarColor "#ff79c6" ""
    blue = xmobarColor "#bd93f9" ""
    white = xmobarColor "#f8f8f2" ""
    yellow = xmobarColor "#f1fa8c" ""
    red = xmobarColor "#ff5555" ""
    lowWhite = xmobarColor "#bbbbbb" ""

-- lowWhite = xmobarColor "#bbbbbb" ""
myManageHook :: ManageHook
myManageHook =
  composeAll
    [ className =? "Gimp" --> doFloat,
      className =? "copyq" --> doFloat,
      isDialog --> doFloat
    ]
