local statusletTimer = nil
local firewallStatusText = nil
local firewallStatusDot = nil
local cccStatusText = nil
local cccStatusDot = nil
local arqStatusText = nil
local arqStatusDot = nil

-- Draw little text/dot pairs in the bottom right corner of the primary display, to indicate firewall/backup status of my machine
function renderStatuslets()
  if (hostname ~= "linym的MacBook Pro") then
    return
  end
  -- Destroy existing Statuslets
  if firewallStatusText then firewallStatusText:delete() end
  if firewallStatusDot then firewallStatusDot:delete() end
  if cccStatusText then cccStatusText:delete() end
  if cccStatusDot then cccStatusDot:delete() end
  if arqStatusText then arqStatusText:delete() end
  if arqStatusDot then arqStatusDot:delete() end

  -- Defines for statuslets - little coloured dots in the corner of my screen that give me status info, see:
  -- https://www.dropbox.com/s/3v2vyhi1beyujtj/Screenshot%202015-03-11%2016.13.25.png?dl=0
  local initialScreenFrame = hs.screen.allScreens()[1]:fullFrame()

  -- Start off by declaring the size of the text/circle objects and some anchor positions for them on screen
  local statusDotWidth = 10
  local statusTextWidth = 30
  local statusTextHeight = 15
  local statusText_x = initialScreenFrame.x + initialScreenFrame.w - statusDotWidth - statusTextWidth
  local statusText_y = initialScreenFrame.y + initialScreenFrame.h - statusTextHeight
  local statusDot_x = initialScreenFrame.x + initialScreenFrame.w - statusDotWidth
  local statusDot_y = statusText_y

  -- Now create the text/circle objects using the sizes/positions we just declared (plus a little fudging to make it all align properly)
  firewallStatusText = hs.drawing.text(hs.geometry.rect(statusText_x + 5,
      statusText_y - (statusTextHeight*2) + 2,
      statusTextWidth,
      statusTextHeight), "FW:")
  cccStatusText = hs.drawing.text(hs.geometry.rect(statusText_x,
      statusText_y - statusTextHeight + 1,
      statusTextWidth,
      statusTextHeight), "CCC:")
  arqStatusText = hs.drawing.text(hs.geometry.rect(statusText_x + 4,
      statusText_y,
      statusTextWidth,
      statusTextHeight), "Arq:")

  firewallStatusDot = hs.drawing.circle(hs.geometry.rect(statusDot_x,
      statusDot_y - (statusTextHeight*2) + 4,
      statusDotWidth,
      statusDotWidth))
  cccStatusDot = hs.drawing.circle(hs.geometry.rect(statusDot_x,
      statusDot_y - statusTextHeight + 3,
      statusDotWidth,
      statusDotWidth))
  arqStatusDot = hs.drawing.circle(hs.geometry.rect(statusDot_x,
      statusDot_y + 2,
      statusDotWidth,
      statusDotWidth))

  -- Finally, configure the rendering style of the text/circle objects, clamp them to the desktop, and show them
  firewallStatusText:setBehaviorByLabels({"canJoinAllSpaces", "stationary"}):setTextSize(11):sendToBack():show(0.5)
  cccStatusText:setBehaviorByLabels({"canJoinAllSpaces", "stationary"}):setTextSize(11):sendToBack():show(0.5)
  arqStatusText:setBehaviorByLabels({"canJoinAllSpaces", "stationary"}):setTextSize(11):sendToBack():show(0.5)

  firewallStatusDot:setBehaviorByLabels({"canJoinAllSpaces", "stationary"}):setFillColor(hs.drawing.color.osx_yellow):setStroke(false):sendToBack():show(0.5)
  cccStatusDot:setBehaviorByLabels({"canJoinAllSpaces", "stationary"}):setFillColor(hs.drawing.color.osx_yellow):setStroke(false):sendToBack():show(0.5)
  arqStatusDot:setBehaviorByLabels({"canJoinAllSpaces", "stationary"}):setFillColor(hs.drawing.color.osx_yellow):setStroke(false):sendToBack():show(0.5)
end

function statusletCallbackFirewall(code, stdout, stderr)
  local color

  if string.find(stdout, "block all non-essential") then
    color = hs.drawing.color.osx_green
  else
    color = hs.drawing.color.osx_red
  end

  firewallStatusDot:setFillColor(color)
end

function statusletCallbackCCC(code, stdout, stderr)
  local color

  if code == 0 then
    color = hs.drawing.color.osx_green
  else
    color = hs.drawing.color.osx_red
  end

  cccStatusDot:setFillColor(color)
end

function statusletCallbackArq(code, stdout, stderr)
  local color

  if code == 0 then
    color = hs.drawing.color.osx_green
  else
    color = hs.drawing.color.osx_red
  end

  arqStatusDot:setFillColor(color)
end

function triggerStatusletsUpdate()
  if (hostname ~= "linym的MacBook Pro") then
    return
  end
  print("triggerStatusletsUpdate")
  hs.task.new("/usr/bin/sudo", statusletCallbackFirewall, {"/usr/libexec/ApplicationFirewall/socketfilterfw", "--getblockall"}):start()
  hs.task.new("/usr/bin/grep", statusletCallbackCCC, {"-q", os.date("%d/%m/%Y"), os.getenv("HOME").."/.cccLast"}):start()
  hs.task.new("/usr/bin/grep", statusletCallbackArq, {"-q", "Arq.*finished backup", "/var/log/system.log"}):start()
end

-- Render our statuslets, trigger a timer to update them regularly, and do an initial update
renderStatuslets()
statusletTimer = hs.timer.new(hs.timer.minutes(5), triggerStatusletsUpdate)
statusletTimer:start()
triggerStatusletsUpdate()
