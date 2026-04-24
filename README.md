# Clear Notifications for macOS

Double-tap Command to clear visible macOS Notification Center banners and alerts.

This uses Hammerspoon because macOS requires Accessibility permission for global key listening and Notification Center automation.

## What to Share

Send this file to someone:

```text
dist/ClearNotificationsInstaller.zip
```

They should unzip it, double-click `ClearNotificationsInstaller.command`, then enable Hammerspoon in:

```text
System Settings > Privacy & Security > Accessibility
```

macOS does not allow this permission to be granted automatically.

## Requirements

```text
macOS
Hammerspoon
Accessibility permission for Hammerspoon
```

## Folder Map

```text
dist/
  Files ready to share.

source/
  Editable installer source.

docs/
  Notes, screenshots, and setup instructions.
```

## Current Files

```text
dist/ClearNotificationsInstaller.command
dist/ClearNotificationsInstaller.zip
source/installer-source.command
```

## Update Flow

1. Edit `source/installer-source.command`.
2. Copy it to `dist/ClearNotificationsInstaller.command`.
3. Rebuild `dist/ClearNotificationsInstaller.zip`.
4. Share the zip.

## GitHub Publish

Suggested repository name:

```text
clear-notifications-macos
```

After authenticating with GitHub CLI:

```bash
gh auth login -h github.com
gh repo create clear-notifications-macos --public --source=. --remote=origin --push
```
