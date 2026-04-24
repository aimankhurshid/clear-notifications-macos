# Clear Notifications for macOS

A small Hammerspoon setup that clears visible macOS notification banners when you double-tap `Command`.

I made this because Notification Center is awkward to automate, and the usual "find the close button" scripts break easily across macOS versions and languages. This one looks for Notification Center alert/banner roles and uses the last available action, which has been more reliable in practice.

## Install

1. Install [Hammerspoon](https://www.hammerspoon.org/).
2. Download and unzip:

```text
dist/ClearNotificationsInstaller.zip
```

3. Double-click `ClearNotificationsInstaller.command`.
4. Enable Hammerspoon here:

```text
System Settings > Privacy & Security > Accessibility
```

That last step has to be done manually. macOS does not let scripts grant Accessibility permission for you.

After that, double-tap `Command` whenever you want to clear visible notifications.

## Files

The shareable build is in `dist/`.

```text
dist/
  ClearNotificationsInstaller.command
  ClearNotificationsInstaller.zip

source/
  installer-source.command

docs/
  setup-for-friends.md
```

If you are sending this to someone, send the zip from `dist/`.

## Updating the Installer

Edit the source file first:

```text
source/installer-source.command
```

Then copy it into `dist/` and rebuild the zip:

```bash
cp source/installer-source.command dist/ClearNotificationsInstaller.command
chmod +x dist/ClearNotificationsInstaller.command
cd dist
zip -q ClearNotificationsInstaller.zip ClearNotificationsInstaller.command
```

## Notes

The installer backs up an existing Hammerspoon config before touching it. It installs the notification clearer as a separate module and adds a small `require("clear_notifications")` block to `~/.hammerspoon/init.lua`.

If the shortcut does not work after installing, quit and reopen Hammerspoon, then choose **Reload Config** from the Hammerspoon menu bar icon.
