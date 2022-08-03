import System.Exit
import XMonad
import XMonad.Actions.CycleWS
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.ManageHelpers (isDialog)
import XMonad.Hooks.StatusBar
import XMonad.Layout.Magnifier (magnifiercz)
import XMonad.Layout.NoBorders (noBorders)
import XMonad.Layout.ThreeColumns
import XMonad.Layout.ToggleLayouts (ToggleLayout (..), toggleLayouts)
import qualified XMonad.StackSet as W
import XMonad.Util.EZConfig
import XMonad.Util.Loggers
import XMonad.Util.NamedScratchpad

-- dollar sign --> https://stackoverflow.com/questions/940382/what-is-the-difference-between-dot-and-dollar-sign

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
  -- defaults
  -- https://wiki.haskell.org/Xmonad/Config_archive/Template_xmonad.hs_(0.9)
  [ ("M-w", spawn "firefox"),
    ("M-R", spawn "nautilus"),
    ("M-S-z", spawn "xscreensaver-command -lock"),
    ("M-r", spawn "st -e ranger"),
    ("M-q", kill),
    ("M-f", sendMessage (Toggle "Full")),
    ("M-l", sendMessage NextLayout),
    ("M-S-t", withFocused $ windows . W.sink), -- retile window
    -- Quit xmonad
    ("M-S-q", io exitSuccess),
    -- ("M-c", spawn "~/.local/bin/xmonad --recompile; ~/.local/bin/xmonad --restart"),
    --------------
    -- SCRATCHPADS
    --------------
    ("M-c", namedScratchpadAction scratchpads "terminal"),
    ("M-S-c", namedScratchpadAction scratchpads "terminal-big"),
    ("M-S-r", namedScratchpadAction scratchpads "ranger"),
    -----------
    -- MOVEMENT
    -----------
    ("M-n", windows W.focusDown),
    ("M-e", windows W.focusUp),
    ("M-S-n", windows W.swapDown),
    ("M-S-e", windows W.swapUp),
    ("M-h", sendMessage Shrink),
    ("M-i", sendMessage Expand),
    -- a basic CycleWS setup
    ("M-ñ", nextScreen), -- need to change promotion bindings
    ("M-S-ñ", shiftNextScreen)
    -- ("M-s-.", swapNextScreen) -- change to mode_switch

    -- , ("M-,",    prevWS)
  ]

removeDefaultKeys = ["M-t", "M-<Space>"]

customLayout = toggleLayouts (noBorders Full) (tiled ||| Mirror tiled ||| threeCol)
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
      className =? "zoom " --> doFloat,
      isDialog --> doFloat
    ]
    <+> namedScratchpadManageHook scratchpads

-- <+> mappend (monoid)

-- scratchpads = [NS "terminal" "st -n scratchpad" (appName =? "scratchpad") defaultFloating] where role = stringProperty "WM_WINDOW_ROLE"

scratchpads :: [NamedScratchpad]
scratchpads =
  [ NS "terminal" "st -n scratchpad" (appName =? "scratchpad") term_dim,
    NS "terminal-big" "st -n scratchpad-big" (appName =? "scratchpad-big") term_big_dim,
    NS "ranger" "st -n ranger -e ranger 2>/dev/null" (appName =? "ranger") defaultFloating
  ]
  where
    term_dim = customFloating $ W.RationalRect l t w h
      where
        h = 0.5
        w = 0.50
        t = 0.75 - h
        l = 0.75 - w

    term_big_dim = customFloating $ W.RationalRect l t w h
      where
        h = 0.9
        w = 0.9
        t = 0.95 - h
        l = 0.95 - w
