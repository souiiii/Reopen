# Phase 18 Deliverable: Settings

## Status

Implemented.

## What This Phase Adds

- Settings model and persistence:
  - `AppSettings`
  - `SettingsRuntime`
  - `SettingsStore`
  - `SettingsManager`
- A real settings window opened from the menu bar Settings item.
- Local `settings.json` persistence in Reopen's Application Support directory.
- Immediate behavior updates where possible:
  - launch at login through `SMAppService`
  - Dock icon visibility through activation policy
  - runtime launch defaults through `SettingsRuntime`
- Launch settings are used by workspace runs:
  - terminal confirmation preference
  - default launch delay
  - global window restore enable/disable
  - preferred terminal app
  - preferred VS Code variant
- Workspace creation uses settings defaults for:
  - new workspace window restore state
  - new terminal command confirmation state
  - new VS Code project editor metadata
- Settings data tools:
  - export workspace data to JSON
  - import workspace data from JSON with confirmation
  - reset app data with confirmation

## Import and Export Scope

Phase 18 provides settings-screen import and export for all workspace data. Import replaces the current workspace list after confirmation. Phase 19 will expand this with richer import summaries, duplicate ID handling, individual workspace export, and stricter unsafe-file rejection.

## Acceptance Criteria Mapping

- Settings persist after restart: `SettingsStore` saves and reloads `settings.json`.
- User can enable launch at login: `SettingsManager` applies `launchAtLogin` through `SMAppService`.
- User can control terminal safety behavior: workspace launches can globally require terminal confirmation.
- User can export and import workspace data: settings screen exposes JSON export/import backed by `WorkspaceImportExportManager`.
- Reset app data requires confirmation: reset is guarded by a destructive confirmation alert and manager-level confirmation check.

## Verification

```text
swift build
scripts/check-workspace-models.sh
scripts/check-storage.sh
scripts/check-workspace-manager.sh
scripts/check-workspace-creation.sh
scripts/check-workspace-editing.sh
scripts/check-app-launching.sh
scripts/check-file-folder-opening.sh
scripts/check-url-opening.sh
scripts/check-terminal-command.sh
scripts/check-vscode-project.sh
scripts/check-workspace-runner.sh
scripts/check-permissions.sh
scripts/check-window-layout.sh
scripts/check-settings.sh
scripts/build-app.sh
plutil -lint Reopen/Resources/Info.plist
codesign --verify --deep --strict build/Reopen.app
```
