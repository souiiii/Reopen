# Phase 14 Deliverable: VS Code Project Support

## Status

Implemented.

## What This Phase Adds

- VS Code project actions now launch through `VSCodeLauncher`.
- The workspace editor can already add a VS Code project by selecting a folder.
- VS Code editor metadata is preserved when saving and editing actions.
- Reopen detects common `code` CLI locations:
  - `/usr/local/bin/code`
  - `/opt/homebrew/bin/code`
  - `/usr/bin/code`
  - the embedded VS Code app CLI under common app locations
- Reopen detects common Visual Studio Code app locations:
  - `/Applications/Visual Studio Code.app`
  - `~/Applications/Visual Studio Code.app`
  - `/Applications/Visual Studio Code - Insiders.app`
  - `~/Applications/Visual Studio Code - Insiders.app`
- If `code` is available, Reopen opens the project folder with the CLI.
- If `code` fails or is unavailable, Reopen falls back to opening the folder with the VS Code app.
- Missing projects, invalid project paths, missing VS Code, and launch failures return clear launch results.

## Launch Order So Far

The runner now executes supported actions in this order:

```text
1. Apps
2. Files
3. Folders
4. URLs
5. VS Code projects
6. Terminal commands
```

Shell scripts and window layouts remain for later phases.

## Acceptance Criteria Mapping

- User can add a project folder: the existing VS Code project button opens a folder picker and stores the selected path.
- Launching workspace opens the folder in VS Code: `WorkspaceAppRunner` now executes `openVSCodeProject` actions through `VSCodeLauncher`.
- App handles missing VS Code gracefully: `VSCodeLauncher` reports `missing_vscode` when neither the CLI nor app is found.
- App does not require the user to manually write `code ~/project`: VS Code launching is first-class and does not require a terminal command action.

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
scripts/build-app.sh
plutil -lint Reopen/Resources/Info.plist
codesign --verify --deep --strict build/Reopen.app
```
