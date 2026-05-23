# Phase 19 Deliverable: Import and Export

## Status

Implemented.

## What This Phase Adds

- `WorkspaceImportExportManager` now supports:
  - exporting all workspaces to JSON
  - exporting one workspace to JSON
  - importing all-workspace envelope JSON
  - importing a single workspace JSON object
  - validating imported workspaces before saving
  - rejecting unsafe import files
  - regenerating imported workspace IDs that duplicate existing or imported IDs
  - returning a structured import summary
- Settings import now adds imported workspaces to the existing list instead of replacing current data.
- The settings screen shows an import summary with each added workspace and whether a duplicate ID was regenerated.
- Manage Workspaces rows include an export action for individual workspace JSON.

## Import Safety

Imports are limited to local `.json` files. Folders, non-JSON files, oversized files, empty files, malformed JSON, unsupported workspace data, and invalid workspace contents are rejected with typed errors instead of crashing or changing saved data.

## Acceptance Criteria Mapping

- User can export workspaces: settings export writes all workspaces, and Manage Workspaces exports individual workspaces.
- User can import previously exported workspaces: Phase 19 imports both all-workspace and single-workspace exports.
- Invalid imports do not crash app: invalid and unsafe files return `WorkspaceImportExportError`.
- Duplicate IDs are regenerated: imported workspace IDs are regenerated when they collide with existing or imported IDs.
- Import result clearly shows what was added: `WorkspaceImportSummary` is displayed in Settings after import.

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
scripts/check-import-export.sh
scripts/build-app.sh
plutil -lint Reopen/Resources/Info.plist
codesign --verify --deep --strict build/Reopen.app
```
