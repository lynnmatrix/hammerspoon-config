local hotkey = require 'hs.hotkey'
local window = require 'hs.window'
local application = require 'hs.application'

key2App = {
  a = 'Atom',
  c = 'Google Chrome',
  d = '钉钉',
  e = 'Evernote',
  f = 'Finder',
  i = 'IntelliJ IDEA',
  m = 'Mail',
  o = 'OmniFocus',
  t = 'iTerm2',
  w = 'WeChat',
  x = 'XMind'
}

for key, app in pairs(key2App) do
  hotkey.bind(hyper, key, function()
      --application.launchOrFocus(app)
      toggle_application(app)
    end)
end

hs.hotkey.bind(hyper, "q", function()
    hs.alert.show("Closing")
    focusWindow = hs.window.focusedWindow()
    for i, window in ipairs(hs.window.allWindows()) do
      if not (focusWindow == window) then
        local app = window:application()
        if (app) then
          if not isInTable(app:name(), killWhiteList) then
            hs.alert.show(app:name())
            app:kill()
          end
        end
      end
    end
  end)

-- Toggle an application between being the frontmost app, and being hidden
function toggle_application(_app)
  -- finds a running applications
  local app = application.find(_app)

  if not app then
    -- application not running, launch app
    application.launchOrFocus(_app)
    return
  end

  -- application running, toggle hide/unhide
  local mainwin = app:mainWindow()
  if mainwin then
    if true == app:isFrontmost() then
      mainwin:application():hide()
    else
      mainwin:application():activate(true)
      mainwin:application():unhide()
      mainwin:focus()
    end
  else
    -- no windows, maybe hide
    if true == app:hide() then
      -- focus app
      application.launchOrFocus(_app)
    else
      -- nothing to do
    end
  end
end

local killWhiteList = {
  "Mail",
  "Google Chrome",
  "OmniFocus",
  "钉钉",
  "WeChat",
  "Evernote",
  "iTerm2",
  "Atom",
  "IntelliJ IDEA"
}

function isInTable(value, tbl)
  for k,v in ipairs(tbl) do
    if v == value then
      return true;
    end
  end

  return false;
end
