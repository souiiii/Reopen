# Phase 15 Deliverable: Workspace Launch Engine

## Status

Implemented.

## What This Phase Adds

- `WorkspaceRunner` is now the central launch engine.
- `WorkspaceAppRunner` remains as a compatibility alias for older checks and call sites.
- Workspace launches validate the workspace before any action runs.
- A permission-checking hook is in place for Phase 16.
- Actions execute in the Phase 15 order:
  - Apps
  - Files
  - Folders
  - URLs
  - VS Code projects
  - Terminal commands
- Action failures do not stop later actions.
- Results now support both action results and layout results.
- Launch progress snapshots are published while the launch runs.
- Menu bar launches run asynchronously so the app remains responsive.
- A progress window appears while the workspace is launching, then the final result summary appears.
- Configurable delays are supported between actions and before window layout restoration.
- A placeholder `WindowLayoutRestorer` preserves the Phase 15 sequence until Phase 17 implements real window movement.

## Launch Sequence

```text
1. Validate workspace
2. Check permissions
3. Open apps
4. Open files
5. Open folders
6. Open URLs
7. Open code projects
8. Run terminal commands
9. Wait briefly
10. Apply window layout
11. Show launch result
```

## Acceptance Criteria Mapping

- User can launch a workspace from the menu bar: menu items now call `WorkspaceRunner.launchWorkspaceActionsAsync`.
- Actions run in the expected order: covered by `scripts/check-workspace-runner.sh`.
- One failed action does not stop the whole launch: runner checks verify a missing file does not stop a later URL.
- User sees a clear summary of what succeeded and failed: final launch result view now includes action and layout results.
- App remains responsive during launch: launches run on a background queue while progress/result windows update on the main thread.

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
scripts/build-app.sh
plutil -lint Reopen/Resources/Info.plist
codesign --verify --deep --strict build/Reopen.app
```
