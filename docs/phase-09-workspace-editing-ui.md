# Phase 9 Deliverable: Workspace Editing UI

## Status

Implemented.

## What This Phase Adds

- Editor support for opening an existing workspace with saved data loaded.
- Manage Workspaces window for selecting workspaces to edit.
- Existing workspace field editing:
  - name
  - icon
  - color
  - description
- Existing action editing.
- Action deletion.
- Action reordering with move up/down controls.
- Save Changes flow through `WorkspaceManager.updateWorkspace`.
- Cancel behavior that leaves manager and storage state untouched.

## Scope Boundary

This phase adds editing UI and update behavior. It does not implement workspace launch behavior, individual action execution, or advanced Phase 17 window layout editing. Existing window layout data is preserved while editing workspace details and actions.

## Acceptance Criteria Mapping

- User can edit every workspace field: edit drafts load and save name, icon, color, and description.
- User can reorder launch actions: action rows include move up/down controls and save the new order.
- Cancel does not modify saved data: edits are held in a local draft until Save Changes.
- Save updates the workspace immediately: save calls `WorkspaceManager.updateWorkspace`, which persists through `WorkspaceStore`.

## Verification

```text
swift build
scripts/check-workspace-models.sh
scripts/check-storage.sh
scripts/check-workspace-manager.sh
scripts/check-workspace-creation.sh
scripts/check-workspace-editing.sh
scripts/build-app.sh
plutil -lint Reopen/Resources/Info.plist
codesign --verify --deep --strict build/Reopen.app
```
