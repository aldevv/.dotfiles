import Control.Monad (liftM2)
import System.Exit
import XMonad
import XMonad.Actions.CycleWS
import XMonad.Actions.SpawnOn
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.FadeInactive
import XMonad.Hooks.InsertPosition (Focus (Newer), Position (Master), insertPosition)
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers (isDialog)
import XMonad.Hooks.StatusBar
import XMonad.Hooks.StatusBar.PP
import XMonad.Hooks.WindowSwallowing (swallowEventHook)
import XMonad.Layout.Gaps
import XMonad.Layout.IndependentScreens (marshallPP)
import XMonad.Layout.Magnifier (magnifiercz)
import XMonad.Layout.NoBorders (noBorders, smartBorders)
import XMonad.Layout.Renamed
import XMonad.Layout.Spacing
import XMonad.Layout.ThreeColumns
import XMonad.Layout.ToggleLayouts (ToggleLayout (..), toggleLayouts)
import XMonad.StackSet qualified as W
import XMonad.Util.EZConfig
import XMonad.Util.Hacks qualified as Hacks
import XMonad.Util.Loggers
import XMonad.Util.NamedScratchpad
import XMonad.Util.Run (hPutStrLn, spawnPipe)

-- check for ideas (good config)
-- https://github.com/alternateved/nixos-config/blob/c480271a7c84f5ef6a7c91f7f88142540552cd9d/config/xmonad/xmonad.hs#L191
-- DT
-- https://gitlab.com/dwt1/dotfiles/-/blob/master/.config/xmonad/xmonad.hs

-- dollar sign --> https://stackoverflow.com/questions/940382/what-is-the-difference-between-dot-and-dollar-sign

myWorkspaces = ["一", "ニ", "三", "四", "五", "六", "七", "八", "九"]

myConfig =
  def
    { workspaces = myWorkspaces,
      modMask = mod4Mask,
      terminal = "st",
      startupHook = myStartupHook,
      layoutHook = customLayout,
      manageHook = myManageHook,
      logHook = myLogHook,
      handleEventHook = swallowEventHook (className =? "Alacritty" <||> className =? "st-256color" <||> className =? "XTerm") (return True) <> Hacks.trayerPaddingXmobarEventHook
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
  -- readable: https://gist.github.com/micrub/aeebe7eb4d2df9e5e203e76a0fd89542
  -- config: https://wiki.haskell.org/Xmonad/Config_archive/Template_xmonad.hs_(0.9)
  [ ("M-S-z", spawn "xscreensaver-command -lock"),
    ("M-r", spawn "st -e ranger"),
    ("M-q", kill),
    ("M-f", sendMessage (Toggle "M")),
    ("M-t", toggleWindowSpacingEnabled >> toggleScreenSpacingEnabled),
    ("M-l", sendMessage NextLayout),
    ("M-S-t", withFocused $ windows . W.sink), -- retile window
    ("M-b", sendMessage ToggleStruts), -- retile window
    -- Quit xmonad
    ("M-S-q", spawn "~/.local/bin/xmonad --recompile; ~/.local/bin/xmonad --restart"),
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
    ("M-v", windows W.swapMaster),
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
    threeCol = renamed [Replace "W"] $ mySpacing 10 $ smartBorders $ magnifiercz 1.3 (ThreeColMid nmaster delta ratio)
    tiled = renamed [Replace "T"] $ mySpacing 10 $ smartBorders $ Tall nmaster delta ratio
    toggleMonocle = toggleLayouts $ renamed [Replace "M"] $ noBorders Full
    nmaster = 1 -- Default number of windows in the master pane
    ratio = 1 / 2 -- Default proportion of screen occupied by master pane
    delta = 3 / 100 -- Percent of screen to increment by when resizing panes

-- PP docs pretty print
-- https://hackage.haskell.org/package/xmonad-contrib-0.17.0/docs/XMonad-Hooks-StatusBar-PP.html
myXmobarPP :: ScreenId -> PP
myXmobarPP s =
  filterOutWsPP
    [scratchpadWorkspaceTag] -- > removes NSP from xmobar NSP cratchpad)
    $ def
      { ppSep = magenta " • ",
        -- ppTitle = xmobarColor "magenta" "" . wrap (white "[") (white "]"),
        ppTitle = formatFocused, -- > the format of the current window title
        ppTitleSanitize = xmobarStrip,
        ppCurrent = currentWs, -- > current workspace
        ppHidden = gold . wrap " " "", -- > hidden workspace color
        -- NOTE: for the focused workspace text color, change fgcolor in xmobar
        -- ppVisible = red . wrap " " "",
        ppHiddenNoWindows = lowWhite . wrap " " "",
        ppUrgent = red . wrap (yellow "!") (yellow "!"),
        -- ppExtras = [logTitles formatFocused formatUnfocused], -- > this becomes "wins" in pporder, if you add more extras, you would add one more to pporder
        ppExtras = [winCount], -- > this becomes "wins" in pporder, if you add more extras, you would add one more to pporder
        ppOrder = \[ws, l, ex, c] -> [ws, l, c, ex] -- > orders stuff in the xmobar (workspaces, layout, title of cur window, and wins, )
        -- ppOrder = \[ws, l, _, wins] -> [ws, l, wins] -- > orders stuff in the xmobar (workspaces, layout, title of cur window, and wins, )
      }
  where
    -- myOrder [ws, l, _, wins] = [ws, l, wins]  here we could, but we used a lambda better
    curWSBarColor = "#8be9fd" -- blue
    currentWs = wrap " " "" . xmobarBorder "Top" curWSBarColor 2
    formatFocused = wrap (white "[") (white "]") . magenta . ppWindow
    formatUnfocused = wrap (lowWhite "[") (lowWhite "]") . blue . ppWindow
    winCount :: X (Maybe String)
    winCount = gets $ Just . show . length . W.integrate' . W.stack . W.workspace . W.current . windowset

    -- Windows should have *some* title, which should not not exceed a
    -- sane length.
    ppWindow :: String -> String
    ppWindow = xmobarRaw . (\w -> if null w then "untitled" else w) . shorten 80

    blue, lowWhite, magenta, red, white, yellow :: String -> String
    magenta = xmobarColor "#ff79c6" ""
    blue = xmobarColor "#bd93f9" ""
    white = xmobarColor "#f8f8f2" ""
    yellow = xmobarColor "#f1fa8c" ""
    gold = xmobarColor "#DAA520" ""
    red = xmobarColor "#ff5555" ""
    lowWhite = xmobarColor "#646464" ""

-- creates a new ManageHook
myManageHook :: ManageHook
myManageHook =
  -- using 'doShift ( myWorkspaces !! 7)' sends program to workspace 8!
  -- doShift "一", this will open program in workspace 1 and move focus to it

  insertPosition -- this is so new windows open in the master area
    Master
    Newer
    <+> composeAll
      [ className =? "Gimp" --> doFloat,
        className =? "copyq" --> doFloat,
        className =? "Slack" --> doShift (myWorkspaces !! 5),
        className =? "firefox" --> doShift (myWorkspaces !! 0),
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
myLogHook =
  fadeInactiveLogHook fadeAmount
  where
    fadeAmount = 1 -- > sets opacity for unfocused windows

myStatusBarSpawner :: Applicative f => ScreenId -> f StatusBarConfig
myStatusBarSpawner (S s) = do
  pure $
    statusBarPropTo
      ("_XMONAD_LOG_" ++ show s)
      ("xmobar -x " ++ show s ++ " ~/.config/xmobar/xmobar" ++ show s ++ ".hs")
      (pure $ myXmobarPP (S s))

myStartupHook :: X ()
myStartupHook = do
  let colorTrayer = "--tint 0x2B2E37"
  spawn ("killall trayer; trayer --edge top --align right --widthtype request --SetDockType true --SetPartialStrut true --expand true --monitor 0 --transparent true --alpha 0 " ++ colorTrayer ++ " --height 15 -l") -- kill current trayer and xmobar on each restart
  -- spawn ("trayer --edge top --align right --widthtype request --SetDockType true --SetPartialStrut true --expand true --monitor 0 --transparent true --alpha 0 " ++ colorTrayer ++ " --height 15 -l")
  -- spawn "sleep 6 && xmobar  -x 0 $HOME/.config/xmobar/xmobar0.hs"
  -- spawn "sleep 6 && xmobar  -x 1 $HOME/.config/xmobar/xmobar1.hs"

-- xsetroot -cursor_name left_ptr

-- ewmhFullscreen lets apps know about the window size

-- xmobar0 :: StatusBarConfig
-- xmobar0 = statusBarPropTo "_XMONAD_LOG_0" "xmobar -x 0 ~/.config/xmobar/xmobar0.hs" (pure myXmobarPP)
--
-- xmobar1 :: StatusBarConfig
-- xmobar1 = statusBarPropTo "_XMONAD_LOG_1" "xmobar -x 1 ~/.config/xmobar/xmobar1.hs" (pure myXmobarPP)

main :: IO ()
main = do
  xmonad
    -- . withSB (xmobar0 <> xmobar1)
    . ewmhFullscreen
    . ewmh
    . dynamicSBs myStatusBarSpawner
    -- . withEasySB (xmobar1 <> xmobar2) toggleStrutsKey
    . docks
    $ myConfig
  where

-- toggleStrutsKey :: XConfig Layout -> (KeyMask, KeySym)
-- toggleStrutsKey XConfig {modMask = m} = (m, xK_b)
-- xmobar1 = statusBarPropTo "_XMONAD_LOG_0" "$HOME/.cabal/bin/xmobar -x 0 /home/kanon/.config/xmobar/xmobar0.hs" (pure myXmobarPP)
-- xmobar2 = statusBarPropTo "_XMONAD_LOG_1" "$HOME/.cabal/bin/xmobar -x 1 $HOME/.config/xmobar/xmobar1.hs" (pure myXmobarPP)

-- barSpawner :: ScreenId -> IO StatusBarConfig
-- barSpawner 0 = pure $ xmobar1
-- barSpawner 1 = pure $ xmobar2
-- barSpawner _ = mempty -- nothing on the rest of the screens
