# Reopen Privacy Policy

Reopen stores workspace and settings data locally on your Mac.

## Local Data

- Workspaces are saved in `~/Library/Application Support/Reopen/workspaces.json`.
- Settings are saved in `~/Library/Application Support/Reopen/settings.json`.
- Diagnostic logs are saved locally and do not include terminal command output unless the user enables that setting.

## Network

Reopen does not send workspace data, settings, or diagnostic logs to a server.

## Permissions

Reopen asks macOS for permissions only when needed:

- Accessibility for best-effort window movement.
- Automation for Terminal commands.
- File access for saved files and folders.
