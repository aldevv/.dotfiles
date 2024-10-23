import Control.Monad (liftM2)
import Data.Char (isSpace)
import Data.List (find)
import Data.Maybe (fromJust, isNothing)
import System.Exit
import XMonad
import XMonad.Actions.CopyWindow
import XMonad.Actions.CycleWS
import XMonad.Actions.SpawnOn
import qualified XMonad.Hooks.DynamicLog as HDL
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.FadeInactive
import XMonad.Hooks.InsertPosition (Focus (Newer), Position (Master), insertPosition)
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers (doCenterFloat, isDialog)
import XMonad.Hooks.Rescreen
import XMonad.Hooks.StatusBar
import XMonad.Hooks.StatusBar.PP
import XMonad.Hooks.WindowSwallowing (swallowEventHook)
import XMonad.Layout.Gaps
import XMonad.Layout.IndependentScreens (marshallPP, withScreens)
import XMonad.Layout.Magnifier (magnifiercz)
import XMonad.Layout.NoBorders (Ambiguity (OnlyScreenFloat, Screen), lessBorders, noBorders, smartBorders)
import XMonad.Hooks.UrgencyHook (NoUrgencyHook (NoUrgencyHook), clearUrgents, focusUrgent, withUrgencyHook)
import XMonad.Layout.Renamed
import XMonad.Layout.Simplest
import XMonad.Layout.Spacing
import XMonad.Layout.ThreeColumns
import XMonad.Layout.ToggleLayouts (ToggleLayout (..), toggleLayouts)
import qualified XMonad.StackSet as S
import qualified XMonad.StackSet as W
import XMonad.Util.EZConfig
import qualified XMonad.Util.Hacks as Hacks
import XMonad.Util.Loggers
import XMonad.Util.NamedScratchpad
import XMonad.Util.Run (hPutStrLn, spawnPipe)

-- check for ideas (good config)
-- https://github.com/alternateved/nixos-config/blob/c480271a7c84f5ef6a7c91f7f88142540552cd9d/config/xmonad/xmonad.hs#L191

-- DT
-- https://gitlab.com/dwt1/dotfiles/-/blob/master/.config/xmonad/xmonad.hs

-- myWorkspaces = ["一", "ニ", "三", "四", "五", "六", "七", "八", "九"]

myWS = ["一", "ニ", "三", "四", "五", "六", "七", "八", "九"]

xmobarEscape = concatMap doubleLts
  where
    doubleLts '<' = "<<"
    doubleLts x = [x]

myWorkspaces :: [String]
myWorkspaces = clickable . (map xmobarEscape) $ myWS
  where
    clickable l =
      [ "<action=xdotool key super+" ++ show (n) ++ ">" ++ ws ++ "</action>"
        | (i, ws) <- zip [1 .. 9] l,
          let n = i
      ]

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
    -- ("M-f", sendMessage (Toggle "M")),
    ("M-f", sendMessage (Toggle "S")),
    ("M-s", windows copyToAll),
    ("M-S-s", killAllOtherCopies),
    ("M-t", toggleWindowSpacingEnabled >> toggleScreenSpacingEnabled),
    ("M-ñ", sendMessage NextLayout),
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
    ("M-l", sendMessage (IncMasterN 1)),
    ("M-u", sendMessage (IncMasterN (-1))),
    -- a basic CycleWS setup
    ("M-,", nextScreen), -- need to change promotion bindings
    ("M-S-,", shiftNextScreen)
    -- ("M-s-.", swapNextScreen) -- change to mode_switch

    -- , ("M-,",    prevWS)
  ]

removeDefaultKeys = ["M-S-p"]

-- https://hackage.haskell.org/package/xmonad-contrib-0.17.0/docs/XMonad-Layout-Spacing.html
mySpacing i = spacingRaw True (Border i i i i) True (Border i i i i) True

customLayout =
  lessBorders Screen -- this is so no borders when only one window in screen
    . avoidStruts
    . toggleSimplest
    $ tiled
      ||| mirrorTiled
      ||| threeCol
  where
    -- https://betweentwocommits.com/blog/xmonad-layouts-guide
    tiled = renamed [Replace "T"] $ mySpacing 10 $ Tall nmaster delta ratio
    mirrorTiled = smartBorders $ Mirror tiled
    threeCol = renamed [Replace "W"] $ mySpacing 10 $ magnifiercz 1.3 (ThreeColMid nmaster delta ratio)
    toggleSimplest = toggleLayouts $ renamed [Replace "S"] $ noBorders Simplest -- monocle one over other
    nmaster = 1 -- Default number of windows in the master pane
    ratio = 1 / 2 -- Default proportion of screen occupied by master pane
    delta = 3 / 100 -- Percent of screen to increment by when resizing panes

myStatusBarSpawner :: (Applicative f) => ScreenId -> f StatusBarConfig
myStatusBarSpawner (S s) = do
  pure $
    statusBarPropTo
      ("_XMONAD_LOG_" ++ show s)
      ("xmobar -x " ++ show s ++ " ~/.config/xmobar/xmobar" ++ show s ++ ".hs")
      (pure $ myXmobarPP (S s))

-- PP docs pretty print
-- https://hackage.haskell.org/package/xmonad-contrib-0.17.0/docs/XMonad-Hooks-StatusBar-PP.html
myXmobarPP :: ScreenId -> PP
myXmobarPP s =
  -- > removes NSP from xmobar NSP cratchpad)
  filterOutWsPP
    [scratchpadWorkspaceTag]
    $ def
      { ppSep = magenta " • ",
        ppTitle = formatFocused, -- > the format of the current window title
        ppTitleSanitize = xmobarStrip,
        ppCurrent = currentWs, -- > current workspace
        ppHidden = gold . wrap " " "", -- > hidden workspace color
        ppHiddenNoWindows = lowWhite . wrap " " "", -- NOTE: for the focused workspace text color, change fgcolor in xmobar
        -- , ppVisible = green -- > instead of <->
        ppUrgent = red . wrap (yellow "!") (yellow "!"),
        -- , ppExtras = [winCount, logLayoutOnScreen s, logDefault (logTitleOnScreen s) (logConst "")] -- > this becomes "wins" in pporder, if you add more extras, you would add one more to pporder
        -- , ppOrder = \[ws, l, _, c, ls, cmdS] -> [ws, ls, c, formatFocused cmdS] -- > orders stuff in the xmobar (workspaces, layout, title of cur window, and wins, )
        ppExtras = [winCount, logLayoutOnScreen s], -- > this becomes "wins" in pporder, if you add more extras, you would add one more to pporder
        ppOrder = \[ws, l, cmd, c, ls] -> [ws, ls, c, cmd] -- > orders stuff in the xmobar (workspaces, layout, title of cur window, and wins, )
      }
  where
    curWSBarColor = "#8be9fd" -- blue
    -- if screen is active do it else
    currentWs = wrap " " "" . xmobarBorder "Top" curWSBarColor 2
    formatFocused = wrap (white "[") (white "]") . magenta . ppWindow
    formatUnfocused = wrap (lowWhite "[") (lowWhite "]") . blue . ppWindow
    winCount :: X (Maybe String)
    winCount = gets $ Just . show . length . W.integrate' . W.stack . W.workspace . W.current . windowset
    -- if number of windows is 0

    -- Windows should have *some* title, which should not not exceed a
    -- sane length.
    ppWindow :: String -> String
    ppWindow = xmobarRaw . (\w -> if null w then "untitled" else w) . shorten 150

    blue, lowWhite, magenta, red, white, yellow :: String -> String
    magenta = xmobarColor "#ff79c6" ""
    blue = xmobarColor "#bd93f9" ""
    white = xmobarColor "#f8f8f2" ""
    yellow = xmobarColor "#f1fa8c" ""
    gold = xmobarColor "#DAA520" ""
    green = xmobarColor "#50fa7b" ""
    red = xmobarColor "#ff5555" ""
    lowWhite = xmobarColor "#646464" ""

myManageHook :: ManageHook
myManageHook =
  insertPosition -- this is so new windows open in the master area
    Master
    Newer
    <+> composeAll
      [ className =? "Gimp" --> doFloat,
        className =? "copyq" --> doFloat,
        className =? "Slack" --> doShift (myWorkspaces !! 5),
        className =? "Insomnia" --> doShift (myWorkspaces !! 3),
        className =? "discord" --> doShift (myWorkspaces !! 6),
        className =? "firefox" --> doShift (myWorkspaces !! 0),
        className =? "Chromium" --> doShift (myWorkspaces !! 0),
        -- pattern that has zoom
        className =? "zoom" --> doShift (myWorkspaces !! 4),
        -- className =? "zoom" --> doFloat,
        className =? "SimpleScreenRecorder" --> doFloat,
        isDialog --> doFloat
      ]
    <+> manageSpawn
    <+> namedScratchpadManageHook scratchpads
    <+> manageDocks
    <+> manageHook def

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

myStartupHook :: X ()
myStartupHook = do
  let colorTrayer = "--tint 0x2B2E37"
  spawn ("killall trayer; trayer --monitor 1 --edge top --align right --widthtype request --SetDockType true --SetPartialStrut true --expand true --transparent true --alpha 0 " ++ colorTrayer ++ " --height 15 -l") -- kill current trayer and xmobar on each restart

  -- not using this
  -- spawn ("killall trayer; trayer --edge top --align right --widthtype request --SetDockType true --SetPartialStrut true --expand true --monitor 1 --transparent true --alpha 0 " ++ colorTrayer ++ " --height 15 -l") -- kill current trayer and xmobar on each restart
  spawn ("sleep 3 && xsetroot -cursor_name left_ptr") -- for mouse pointer

myAfterRescreenHook :: X ()
myAfterRescreenHook = do
  spawn "killall trayer; trayer --monitor 1 --edge top --align right --widthtype request --SetDockType true --SetPartialStrut true --expand true --transparent true --alpha 0 --height 15 -l" -- kill current trayer and xmobar on each restart
  spawn "sleep 3 && xsetroot -cursor_name left_ptr" -- for mouse pointer --TODO: is this needed?
  spawn "set_wall"
  -- spawn "notify-send 'Xmonad' 'Rescreened'"
  spawn "xmonad --restart"

-- invoke autorandr
myRandrChangeHook :: X ()
myRandrChangeHook = do
  spawn "autorandr --change"

myRescreenCfg =
  def
    { afterRescreenHook = myAfterRescreenHook,
      randrChangeHook = myRandrChangeHook
    }

myConfig = def
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

main :: IO ()
main = do
  xmonad
    . docks
    . rescreenHook myRescreenCfg
    . ewmh
    . ewmhFullscreen
    . withUrgencyHook NoUrgencyHook
    . dynamicSBs myStatusBarSpawner
    $ myConfig
