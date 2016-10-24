-- Watchers and other useful objects
local configFileWatcher = nil
local wifiWatcher = nil
local screenWatcher = nil
local usbWatcher = nil
local caffeinateWatcher = nil
local appWatcher = nil

-- Defines for WiFi watcher
local homeSSID = "Huawei*" -- My home WiFi SSID
local lastSSID = hs.wifi.currentNetwork()

-- Defines for caffeinate watcher
local shouldUnmuteOnScreenWake = nil

-- Callback function for application events
function applicationWatcher(appName, eventType, appObject)
  if (eventType == hs.application.watcher.activated) then
    if (appName == "Finder") then
      -- Bring all Finder windows forward when one gets activated
      appObject:selectMenuItem({"Window", "Bring All to Front"})
    elseif (appName == "iTunes") then
      -- Ensure the MiniPlayer window is visible and correctly placed, since it likes to hide an awful lot
      state = appObject:findMenuItem({"Window", "MiniPlayer"})
      if state and not state["ticked"] then
        appObject:selectMenuItem({"Window", "MiniPlayer"})
      end
      _animationDuration = hs.window.animationDuration
      hs.window.animationDuration = 0
      hs.layout.apply({ iTunesMiniPlayerLayout })
      hs.window.animationDuration = _animationDuration
    end
  elseif (eventType == hs.application.watcher.launching) then
    if (appName == "Call of Duty: Modern Warfare 3") then
      print("CoD Starting")
      hs.itunes.pause()
      local tbDisplay = hs.screen.findByName("Thunderbolt Display")
      if (tbDisplay) then
        tbDisplay:setPrimary()
      end
    end
  elseif (eventType == hs.application.watcher.terminated) then
    if (appName == "Call of Duty: Modern Warfare 3") then
      print("CoD Stopping")
      local mbDisplay = hs.screen.findByName("Color LCD")
      if (mbDisplay) then
        mbDisplay:setPrimary()
      end
      if hs.screen.findByName("Thunderbolt Display") then
        hs.layout.apply(dual_display)
      end
    end
  end
end

-- Callback function for WiFi SSID change events
function ssidChangedCallback()
  newSSID = hs.wifi.currentNetwork()

  print("ssidChangedCallback: old:"..(lastSSID or "nil").." new:"..(newSSID or "nil"))
  if newSSID == homeSSID and lastSSID ~= homeSSID then
    -- We have gone from something that isn't my home WiFi, to something that is
    home_arrived()
  elseif newSSID ~= homeSSID and lastSSID == homeSSID then
    -- We have gone from something that is my home WiFi, to something that isn't
    home_departed()
  end

  lastSSID = newSSID
end

-- Callback function for USB device events
function usbDeviceCallback(data)
  print("usbDeviceCallback: "..hs.inspect(data))
  if (data["productName"] == "ScanSnap S1300i") then
    event = data["eventType"]
    if (event == "added") then
      hs.application.launchOrFocus("ScanSnap Manager")
    elseif (event == "removed") then
      app = hs.appfinder.appFromName("ScanSnap Manager")
      app:kill()
    end
  end
end

-- Callback function for caffeinate events
function caffeinateCallback(eventType)
  if (eventType == hs.caffeinate.watcher.screensDidSleep) then
    officeLED:zoneOff(2)
    officeLED:zoneOff(2)

    if hs.itunes.isPlaying() then
      hs.itunes.pause()
    end
    local output = hs.audiodevice.defaultOutputDevice()
    if output:muted() then
      shouldUnmuteOnScreenWake = false
    else
      shouldUnmuteOnScreenWake = true
    end
    output:setMuted(true)
  elseif (eventType == hs.caffeinate.watcher.screensDidWake) then
    officeLED:zoneOn(2)
    officeLED:zoneColor(2, math.random(0, 255))
    officeLED:zoneBrightness(2, hs.milight.minBrightness)

    if shouldUnmuteOnScreenWake then
      hs.audiodevice.defaultOutputDevice():setMuted(false)
    end
  end
end

-- Perform tasks to configure the system for my home WiFi network
function home_arrived()
  hs.audiodevice.defaultOutputDevice():setVolume(25)

  -- Note: sudo commands will need to have been pre-configured in /etc/sudoers, for passwordless access, e.g.:
  -- cmsj ALL=(root) NOPASSWD: /usr/libexec/ApplicationFirewall/socketfilterfw --setblockall *
  hs.task.new("/usr/bin/sudo", function() end, {"/usr/libexec/ApplicationFirewall/socketfilterfw", "--setblockall", "off"})

  -- Mount my mac mini's DAS
  -- hs.applescript.applescript([[
  -- tell application "Finder"
  -- try
  -- mount volume "smb://cmsj@servukipa._smb._tcp.local/Data"
  -- end try
  -- end tell
  -- ]])
  triggerStatusletsUpdate()
  hs.notify.new({
      title='Hammerspoon',
      informativeText='Unmuted volume, mounted volumes, disabled firewall'
    }):send()
end

-- Perform tasks to configure the system for any WiFi network other than my home
function home_departed()
  hs.audiodevice.defaultOutputDevice():setVolume(0)
  hs.task.new("/usr/bin/sudo", function() end, {"/usr/libexec/ApplicationFirewall/socketfilterfw", "--setblockall", "on"})
  -- hs.applescript.applescript([[
  -- tell application "Finder"
  -- eject "Data"
  -- end tell
  -- ]])
  -- triggerStatusletsUpdate()

  hs.notify.new({
      title='Hammerspoon',
      informativeText='Muted volume, unmounted volumes, enabled firewall'
    }):send()
end

-- Create and start our callbacks
appWatcher = hs.application.watcher.new(applicationWatcher):start()

screenWatcher = hs.screen.watcher.new(screensChangedCallback)
screenWatcher:start()

wifiWatcher = hs.wifi.watcher.new(ssidChangedCallback)
wifiWatcher:start()

if (hostname == "linym的MacBook Pro") then
  usbWatcher = hs.usb.watcher.new(usbDeviceCallback)
  usbWatcher:start()

  caffeinateWatcher = hs.caffeinate.watcher.new(caffeinateCallback)
  caffeinateWatcher:start()
end

-- Make sure we have the right location settings
if hs.wifi.currentNetwork() == "Huawei" then
  home_arrived()
else
  home_departed()
end
