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
-- Uses Accessibility directly, so it doesn't need permission to control System Events.

local lastCmdTap = 0
local cmdDown = false
local usedWithOtherKey = false
local threshold = 0.45

local function findNotifications(el, found, depth)
  if depth > 15 then return end
  local sr = el:attributeValue("AXSubrole") or ""
  if sr:find("^AXNotificationCenter") then
    table.insert(found, el)
    return
  end
  for _, c in ipairs(el:attributeValue("AXChildren") or {}) do
    findNotifications(c, found, depth + 1)
  end
end

local function closeAction(el)
  for _, a in ipairs(el:actionNames() or {}) do
    if a:find("Clear All") then return a end
  end
  for _, a in ipairs(el:actionNames() or {}) do
    if a:find("Close") then return a end
  end
end

local function clearNotifications()
  local app = hs.application.applicationsForBundleID("com.apple.notificationcenterui")[1]
  if not app then return 0 end
  local ax = hs.axuielement.applicationElement(app)
  local cleared = 0
  for _ = 1, 20 do
    local found = {}
    for _, w in ipairs(ax:attributeValue("AXWindows") or {}) do
      findNotifications(w, found, 0)
    end
    local target, action
    for _, n in ipairs(found) do
      action = closeAction(n)
      if action then target = n break end
    end
    if not target then break end
    target:performAction(action)
    cleared = cleared + 1
    hs.timer.usleep(150000)
  end
  return cleared
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
          hs.timer.doAfter(0, clearNotifications)
        else
          lastCmdTap = now
        end
      end
    end
  end

  return false
end)

_clearNotificationsCmdWatcher:start()

-- macOS sometimes turns event taps off on its own, so turn it back on
if _clearNotificationsWatchdog then
  _clearNotificationsWatchdog:stop()
end

_clearNotificationsWatchdog = hs.timer.doEvery(5, function()
  if not _clearNotificationsCmdWatcher:isEnabled() then
    _clearNotificationsCmdWatcher:start()
  end
end)

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

osascript -e 'display dialog "Installed. In System Settings > Privacy & Security > Accessibility, enable Hammerspoon. Then double-tap Command to clear notifications." buttons {"OK"} default button "OK"'
