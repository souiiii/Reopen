# Phase 11 Deliverable: File and Folder Opening

## Status

Implemented.

## What This Phase Adds

- File picker action creation using `NSOpenPanel`.
- Folder picker action creation using `NSOpenPanel`.
- Security-scoped bookmark data capture for selected files and folders where available.
- `FileFolderOpener` for opening saved files and folders with `NSWorkspace`.
- Missing file detection.
- Missing folder detection.
- Invalid file/folder path detection.
- Launch results for file and folder successes and failures.
- Workspace launch now runs known action types in this order:
  - apps
  - files
  - folders
- Missing file/folder failures do not stop later file/folder actions.
- Launch result repair buttons for missing files and folders.

## Repair Behavior

When a launch result contains `missing_file` or `missing_folder`, the result window shows a `Repair` button. Repair opens the matching picker, replaces the saved action path and bookmark data, and persists the updated workspace through `WorkspaceManager.updateWorkspace`.

## Scope Boundary

Phase 11 only executes app, file, and folder actions. URL, terminal, VS Code, and layout actions remain for later phases.

## Acceptance Criteria Mapping

- User can add files: implemented through `FilePicker`.
- User can add folders: implemented through `FolderPicker`.
- Launching workspace opens them correctly: `WorkspaceAppRunner` now runs `openFile` and `openFolder` actions through `FileFolderOpener`.
- Missing file/folder errors do not stop the whole workspace launch: each action records its own result and the runner continues.
- User sees which item failed: launch results show failed action title, message, and repair button when applicable.

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
scripts/build-app.sh
plutil -lint Reopen/Resources/Info.plist
codesign --verify --deep --strict build/Reopen.app
```
