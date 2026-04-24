#!/bin/bash
set -e

HS_DIR="$HOME/.hammerspoon"
INIT_FILE="$HS_DIR/init.lua"
MODULE_FILE="$HS_DIR/clear_notifications.lua"
BACKUP_FILE="$INIT_FILE.backup.$(date +%Y%m%d-%H%M%S)"

mkdir -p "$HS_DIR"
touch "$INIT_FILE"
cp "$INIT_FILE" "$BACKUP_FILE"

cat > "$MODULE_FILE" <<'LUA'
-- Double-tap Command to clear visible Notification Center banners/alerts.
hs.allowAppleScript(true)

local lastCmdTap = 0
local cmdDown = false
local usedWithOtherKey = false
local threshold = 0.45

local jxa = [[
let remainingTries = 3

while (true) {
  try {
    Application("System Events")
      .applicationProcesses.byName("NotificationCenter")
      .windows[0]
      .entireContents()
      .find(item => item.subrole()?.startsWith("AXNotificationCenter"))
      .actions()
      .slice(-1)[0]
      .perform()
  } catch {
    remainingTries--
    if (remainingTries < 1) break
  }
}
]]

local function clearNotifications()
  hs.timer.doAfter(0, function()
    hs.osascript.javascript(jxa)
  end)
end

local function onlyCmd(flags)
  return flags.cmd and not flags.alt and not flags.ctrl and not flags.shift and not flags.fn
end

if _clearNotificationsCmdWatcher then
  _clearNotificationsCmdWatcher:stop()
end

_clearNotificationsCmdWatcher = hs.eventtap.new({
  hs.eventtap.event.types.flagsChanged,
  hs.eventtap.event.types.keyDown
}, function(event)
  local eventType = event:getType()

  if eventType == hs.eventtap.event.types.keyDown and cmdDown then
    usedWithOtherKey = true
    return false
  end

  if eventType == hs.eventtap.event.types.flagsChanged then
    local flags = event:getFlags()
    local keyCode = event:getKeyCode()
    local isCmdKey = keyCode == 55 or keyCode == 54

    if isCmdKey and onlyCmd(flags) and not cmdDown then
      cmdDown = true
      usedWithOtherKey = false
    elseif isCmdKey and not flags.cmd and cmdDown then
      cmdDown = false

      if not usedWithOtherKey then
        local now = hs.timer.secondsSinceEpoch()

        if now - lastCmdTap <= threshold then
          lastCmdTap = 0
          clearNotifications()
        else
          lastCmdTap = now
        end
      end
    end
  end

  return false
end)

_clearNotificationsCmdWatcher:start()
hs.alert.show("Double-tap Command notification clearer is ready")
LUA

if ! grep -Fq 'require("clear_notifications")' "$INIT_FILE"; then
  cat >> "$INIT_FILE" <<'LUA'

-- Clear Notifications: begin
local ok, err = pcall(require, "clear_notifications")
if not ok then
  hs.alert.show("Clear Notifications error: " .. tostring(err))
end
-- Clear Notifications: end
LUA
fi

if ! open -Ra "Hammerspoon" >/dev/null 2>&1; then
  open "https://www.hammerspoon.org/"
  osascript -e 'display dialog "The shortcut files are installed. Install Hammerspoon from the page that opened, then run this installer again." buttons {"OK"} default button "OK"'
  exit 0
fi

osascript -e 'quit app "Hammerspoon"' >/dev/null 2>&1 || true
sleep 1
open -a "Hammerspoon"
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility" >/dev/null 2>&1 || true

osascript -e 'display dialog "Installed. In System Settings > Privacy & Security > Accessibility, enable Hammerspoon. If macOS asks whether Hammerspoon can control System Events, click Allow. Then double-tap Command to clear notifications." buttons {"OK"} default button "OK"'
