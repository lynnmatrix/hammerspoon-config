local screen_switch_key = '.';

------------- Multiple Screen Focus Switch --------------- {{{

--One hotkey should just suffice for dual-display setups as it will naturally
--cycle through both.
--A second hotkey to reverse the direction of the focus-shift would be handy
--for setups with 3 or more displays.

--Predicate that checks if a window belongs to a screen
local function isInScreen(sc, win)
  return win:screen() == sc
end

local function moveMouseToScreen(sc)
  local pt = geometry.rectMidPoint(sc:fullFrame())
  mouse.setAbsolutePosition(pt)
end

local function focusScreen(sc, moveMouse)
  --Get windows within screen, ordered from front to back.
  --If no windows exist, bring focus to desktop. Otherwise, set focus on
  --front-most application window.
  if not sc then return end

  local windows = fnutils.filter(
    window.orderedWindows(),
    fnutils.partial(isInScreen, sc))
  local windowToFocus = #windows > 0 and windows[1] or window.desktop()
  windowToFocus:focus()

  if moveMouse then moveMouseToScreen(sc) end
end

--Bring focus to next display/screen
hs.hotkey.bind(hyper, screen_switch_key, function ()
    local focused = window.focusedWindow()
    if not focused then return end
    local sc = focused:screen()
    if not sc then return end
    focusScreen(window.focusedWindow():screen():next(), true)
  end)

-- END DISPLAY FOCUS SWITCHING -- }}}

-- Defines for screen watcher
local lastNumberOfScreens = #hs.screen.allScreens()

-- Define monitor names for layout purposes
local display_primary = "Color LCD"
local display_monitor = "Thunderbolt Display"

-- Define window layouts
-- Format reminder:
-- {"App name", "Window name", "Display Name", "unitrect", "framerect", "fullframerect"},
local iTunesMiniPlayerLayout = {"iTunes", "MiniPlayer", display_primary, nil, nil, hs.geometry.rect(0, -48, 400, 48)}
local internal_display = {
  {"iTerm2", nil, display_primary, hs.layout.maximized, nil, nil},
  {"Finder", nil, display_primary, hs.geometry.unitrect(0, 0, 0.5, 0.5), nil, nil},
  {"NeteaseMusic", nil, display_primary, hs.layout.left50, nil, nil},
  {"WeChat", nil, display_primary, hs.layout.left50, nil, nil},
  {"Dash", nil, display_primary, hs.layout.left70, nil, nil},
  {"Safari", nil, display_primary, hs.layout.maximized, nil, nil},
  {"Google Chrome", nil, display_primary, hs.layout.maximized, nil, nil},
  {"OmniFocus", nil, display_primary, hs.layout.maximized, nil, nil},
  {"Mail", nil, display_primary, hs.layout.maximized, nil, nil},
  {"Calendar", nil, display_primary, hs.layout.maximized, nil, nil},
  {"Evernote", nil, display_primary, hs.layout.maximized, nil, nil},
  {"iTunes", "iTunes", display_primary, hs.layout.maximized, nil, nil},
  iTunesMiniPlayerLayout,
}

local dual_display = {
  {"iTerm2", nil, display_monitor, hs.layout.maximized, nil, nil},
  {"Safari", nil, display_primary, hs.layout.right50, nil, nil},
  {"Google Chrome", nil, display_primary, hs.layout.right50, nil, nil},
  {"OmniFocus", "HP", display_monitor, hs.geometry.unitrect(3/8, 0, 3/8, 0.5), nil, nil},
  {"OmniFocus", "Forecast", display_monitor, hs.geometry.unitrect(3/8, 0.5, 3/8, 0.5), nil, nil},
  {"Mail", nil, display_primary, hs.geometry.unitrect(0, 0.5, 0.5, 0.5), nil, nil},
}

-- Hotkeys to trigger defined layouts
hs.hotkey.bind(hyper, '1', function() hs.layout.apply(internal_display) end)
hs.hotkey.bind(hyper, '2', function() hs.layout.apply(dual_display) end)

-- Callback function for changes in screen layout
function screensChangedCallback()
  print("screensChangedCallback")
  newNumberOfScreens = #hs.screen.allScreens()

  -- FIXME: This is awful if we swap primary screen to the external display. all the windows swap around, pointlessly.
  if lastNumberOfScreens ~= newNumberOfScreens then
    if newNumberOfScreens == 1 then
      hs.layout.apply(internal_display)
    elseif newNumberOfScreens == 2 then
      hs.layout.apply(dual_display)
    end
  end

  lastNumberOfScreens = newNumberOfScreens

  renderStatuslets()
  triggerStatusletsUpdate()
end
