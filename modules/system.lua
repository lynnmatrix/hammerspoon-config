local mouseCircle = nil
local mouseCircleTimer = nil

-- Seed the RNG
math.randomseed(os.time())

-- Capture the hostname, so we can make this config behave differently across my Macs
hostname = hs.host.localizedName()

-- Ensure the IPC command line client is available
hs.ipc.cliInstall()

-- Define audio device names for headphone/speaker switching
local headphoneDevice = "Built-in Output"
local speakerDevice = "Audioengine 2_ "

-- Define default brightness for MiLight extension
local brightness = 13
local officeLED = hs.milight.new("10.0.88.21")

-- Toggle between speaker and headphone sound devices (useful if you have multiple USB soundcards that are always connected)
function toggle_audio_output()
  local current = hs.audiodevice.defaultOutputDevice()
  local speakers = hs.audiodevice.findOutputByName(speakerDevice)
  local headphones = hs.audiodevice.findOutputByName(headphoneDevice)

  if not speakers or not headphones then
    hs.notify.new({title="Hammerspoon", informativeText="ERROR: Some audio devices missing", ""}):send()
    return
  end

  if current:name() == speakers:name() then
    headphones:setDefaultOutputDevice()
  else
    speakers:setDefaultOutputDevice()
  end
  hs.notify.new({
      title='Hammerspoon',
      informativeText='Default output device:'..hs.audiodevice.defaultOutputDevice():name()
    }):send()
end

-- Toggle Skype between muted/unmuted, whether it is focused or not
function toggleSkypeMute()
  local skype = hs.appfinder.appFromName("Skype")
  if not skype then
    return
  end

  local lastapp = nil
  if not skype:isFrontmost() then
    lastapp = hs.application.frontmostApplication()
    skype:activate()
  end

  if not skype:selectMenuItem({"Conversations", "Mute Microphone"}) then
    skype:selectMenuItem({"Conversations", "Unmute Microphone"})
  end

  if lastapp then
    lastapp:activate()
  end
end

-- I always end up losing my mouse pointer, particularly if it's on a monitor full of terminals.
-- This draws a bright red circle around the pointer for a few seconds
function mouseHighlight()
  if mouseCircle then
    mouseCircle:delete()
    if mouseCircleTimer then
      mouseCircleTimer:stop()
    end
  end
  mousepoint = hs.mouse.getAbsolutePosition()
  mouseCircle = hs.drawing.circle(hs.geometry.rect(mousepoint.x-40, mousepoint.y-40, 80, 80))
  mouseCircle:setStrokeColor({["red"]=1,["blue"]=0,["green"]=0,["alpha"]=1})
  mouseCircle:setFill(false)
  mouseCircle:setStrokeWidth(5)
  mouseCircle:bringToFront(true)
  mouseCircle:show(0.5)

  mouseCircleTimer = hs.timer.doAfter(3, function()
      mouseCircle:hide(0.5)
      hs.timer.doAfter(0.6, function() mouseCircle:delete() end)
    end)
end

-- This is a function that fetches the current URL from Chrome and types it
function typeCurrentChromeURL()
  script = [[
  tell application "Google Chrome"
  set currentURL to URL of document 1
  end tell

  return currentURL
  ]]
  ok, result = hs.applescript(script)
  if (ok) then
    hs.eventtap.keyStrokes(result)
  end
end
-- Rather than switch to Chrome, copy the current URL, switch back to the previous app and paste,
hs.hotkey.bind(hyper, 'u', typeCurrentChromeURL)

-- Hotkeys to control the lighting in my office
local officeBrightnessDown = function()
  brightness = brightness - 1
  brightness = officeLED:zoneBrightness(1, brightness)
  officeLED:zoneBrightness(2, hs.milight.minBrightness)
end
local officeBrightnessUp = function()
  brightness = brightness + 1
  brightness = officeLED:zoneBrightness(1, brightness)
  officeLED:zoneBrightness(2, hs.milight.minBrightness)
end
hs.hotkey.bind({}, 'f5', officeBrightnessDown, nil, officeBrightnessDown)
hs.hotkey.bind({}, 'f6', officeBrightnessUp, nil, officeBrightnessUp)
hs.hotkey.bind(hyper, 'f5', function() brightness = officeLED:zoneBrightness(0, hs.milight.minBrightness) end)
hs.hotkey.bind(hyper, 'f6', function()
    brightness = officeLED:zoneBrightness(1, hs.milight.maxBrightness)
    officeLED:zoneBrightness(2, hs.milight.minBrightness)
  end)

--hs.hotkey.bind(hyper, 'd', mouseHighlight)

-- Type the current clipboard, to get around web forms that don't let you paste
-- (Note: I have Fn-v mapped to F17 in Karabiner)
hs.urlevent.bind('fnv', function() hs.eventtap.keyStrokes(hs.pasteboard.getContents()) end)

-- Misc hotkeys
hs.hotkey.bind(hyper, 'y', hs.toggleConsole)
hs.hotkey.bind(hyper, 'n', function() hs.task.new("/usr/bin/open", nil, {os.getenv("HOME")}):start() end)
-- hs.hotkey.bind(hyper, 'c', caffeineClicked)
hs.hotkey.bind(hyper, 'Escape', toggle_audio_output)
hs.hotkey.bind(hyper, 'v', function()
    device = hs.audiodevice.defaultInputDevice()
    device:setMuted(not device:muted())
  end)
-- auto lock screen
hs.hotkey.bind(hyper, '`', function()
    os.execute("/System/Library/CoreServices/Menu\\ Extras/User.menu/Contents/Resources/CGSession -suspend")
  end)
