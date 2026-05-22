# Phase 8 Deliverable: Workspace Creation UI

## Status

Implemented.

## What This Phase Adds

- Workspace editor window for creating new workspaces.
- Workspace details section:
  - name
  - optional icon
  - optional color
  - description
- Actions section with add controls:
  - Add App
  - Add File
  - Add Folder
  - Add URL
  - Add Terminal Command
  - Add VS Code Project
- Action list with inline fields for URL, terminal command, and VS Code project actions.
- Save and Cancel controls.
- Form validation before saving.
- Menu bar `Create Workspace` now opens the real creation window.
- Successful saves go through `WorkspaceManager`, persist immediately, and refresh the menu.

## Scope Boundary

This phase creates the workspace creation screen. It does not implement the full editing workflow from Phase 9, individual action launch behavior from Phases 10-15, or settings from Phase 18.

## Acceptance Criteria Mapping

- User can create a workspace without needing technical knowledge: the editor uses labeled fields, add-action buttons, and system pickers for apps, files, and folders.
- User cannot save a workspace with no name: empty names disable save and are rejected by the draft model and `WorkspaceValidator`.
- User can add at least one action: the editor supports all action buttons listed in the implementation plan.
- Workspace appears in menu bar immediately after saving: `WorkspaceManager.onWorkspacesChanged` updates `AppState`, and `MenuBarController` rebuilds the menu.

## Verification

```text
swift build
scripts/check-workspace-models.sh
scripts/check-storage.sh
scripts/check-workspace-manager.sh
scripts/check-workspace-creation.sh
scripts/build-app.sh
plutil -lint Reopen/Resources/Info.plist
codesign --verify --deep --strict build/Reopen.app
```
