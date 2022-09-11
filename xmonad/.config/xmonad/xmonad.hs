import System.Exit
import XMonad
import XMonad.Actions.CycleWS
import XMonad.Actions.SpawnOn
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.FadeInactive
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers (isDialog)
import XMonad.Hooks.StatusBar
import XMonad.Layout.Gaps
import XMonad.Layout.Magnifier (magnifiercz)
import XMonad.Layout.NoBorders (noBorders)
import XMonad.Layout.Renamed
import XMonad.Layout.Spacing
import XMonad.Layout.ThreeColumns
import XMonad.Layout.ToggleLayouts (ToggleLayout (..), toggleLayouts)
import qualified XMonad.StackSet as W
import XMonad.Util.EZConfig
import XMonad.Util.Loggers
import XMonad.Util.NamedScratchpad

-- check for ideas (good config)
-- https://github.com/alternateved/nixos-config/blob/c480271a7c84f5ef6a7c91f7f88142540552cd9d/config/xmonad/xmonad.hs#L191
-- DT
-- https://gitlab.com/dwt1/dotfiles/-/blob/master/.config/xmonad/xmonad.hs

-- dollar sign --> https://stackoverflow.com/questions/940382/what-is-the-difference-between-dot-and-dollar-sign

myConfig =
  def
    { workspaces = ["1", "2", "3", "4", "5", "6", "7", "8", "9"],
      modMask = mod4Mask,
      terminal = "st",
      layoutHook = customLayout,
      manageHook = myManageHook,
      logHook = myLogHook
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
    ("M-t", toggleWindowSpacingEnabled >> toggleScreenSpacingEnabled),
    ("M-l", sendMessage NextLayout),
    ("M-S-t", withFocused $ windows . W.sink), -- retile window
    ("M-b", sendMessage ToggleStruts), -- retile window
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

removeDefaultKeys = ["M-S-p"]

-- gaps [(U,18), (R,23)] $ toggleLayouts ...
-- gaps [(U, 18), (D, 18), (R, 18), (L, 18)] $
-- spacingRaw True (Border 0 10 10 10) True (Border 10 10 10 10) True

-- https://hackage.haskell.org/package/xmonad-contrib-0.17.0/docs/XMonad-Layout-Spacing.html
mySpacing i = spacingRaw True (Border i i i i) True (Border i i i i) True

-- first True is smartBorder, no spaces when only one window
-- define a screen border
-- True for activate that border
-- define a window border
-- True for activate that window border

customLayout =
  avoidStruts $
    toggleMonocle $
      tiled
        ||| Mirror tiled
        ||| threeCol
  where
    threeCol = renamed [Replace "3"] $ mySpacing 10 $ magnifiercz 1.3 (ThreeColMid nmaster delta ratio)
    tiled = renamed [Replace "T"] $ mySpacing 10 $ Tall nmaster delta ratio
    toggleMonocle = toggleLayouts $ noBorders Full
    nmaster = 1 -- Default number of windows in the master pane
    ratio = 1 / 2 -- Default proportion of screen occupied by master pane
    delta = 3 / 100 -- Percent of screen to increment by when resizing panes

-- PP docs pretty print
-- https://hackage.haskell.org/package/xmonad-contrib-0.17.0/docs/XMonad-Hooks-StatusBar-PP.html
myXmobarPP :: PP
myXmobarPP =
  filterOutWsPP
    [scratchpadWorkspaceTag] -- > removes NSP from xmobar NSP cratchpad)
    def
      { ppSep = magenta " • ",
        ppTitleSanitize = xmobarStrip,
        ppCurrent = currentWs, -- > current workspace
        ppHidden = white . wrap " " "", -- > hidden workspace
        ppHiddenNoWindows = lowWhite . wrap " " "",
        ppUrgent = red . wrap (yellow "!") (yellow "!"),
        -- ppTitle = xmobarColor "magenta" "" . wrap (white "[") (white "]"),
        ppTitle = formatFocused, -- > the format of the current window title
        -- ppExtras = [logTitles formatFocused formatUnfocused], -- > this becomes "wins" in pporder, if you add more extras, you would add one more to pporder
        ppOrder = \[ws, l, c, _] -> [ws, l, c] -- > orders stuff in the xmobar (workspaces, layout, title of cur window, and wins, )
        -- ppOrder = \[ws, l, _, wins] -> [ws, l, wins] -- > orders stuff in the xmobar (workspaces, layout, title of cur window, and wins, )
      }
  where
    -- myOrder [ws, l, _, wins] = [ws, l, wins]  here we could, but we used a lambda better
    currentWs = wrap " " "" . xmobarBorder "Top" "#8be9fd" 2
    formatFocused = wrap (white "[") (white "]") . magenta . ppWindow
    formatUnfocused = wrap (lowWhite "[") (lowWhite "]") . blue . ppWindow

    -- Windows should have *some* title, which should not not exceed a
    -- sane length.
    ppWindow :: String -> String
    ppWindow = xmobarRaw . (\w -> if null w then "untitled" else w) . shorten 80

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
      className =? "Slack" --> doShift "6",
      className =? "Workspacesclient" --> doShift "3",
      className =? "Zoom" --> doShift "7",
      -- className =? "zoom " --> doFloat,
      className =? "SimpleScreenRecorder" --> doFloat,
      isDialog --> doFloat
    ]
    <+> manageSpawn
    <+> namedScratchpadManageHook scratchpads
    <+> manageDocks
    <+> manageHook def

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

myLogHook :: X ()
myLogHook = fadeInactiveLogHook fadeAmount
  where
    -- fadeAmount = 0.95
    fadeAmount = 1 -- > sets opacity for unfocused windows

-- ewmhFullscreen lets apps know about the window size
main :: IO ()
main =
  xmonad
    . ewmhFullscreen
    . ewmh
    . withEasySB (statusBarProp "~/.cabal/bin/xmobar -x 1" (pure myXmobarPP)) toggleStrutsKey
    . docks
    $ myConfig
  where
    toggleStrutsKey :: XConfig Layout -> (KeyMask, KeySym)
    toggleStrutsKey XConfig {modMask = m} = (m, xK_b)
