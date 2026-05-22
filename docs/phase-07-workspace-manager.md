# Phase 7 Deliverable: Workspace Manager

## Status

Implemented.

## What This Phase Adds

- `WorkspaceValidator` for workspace, action, layout, and ID validation.
- `WorkspaceManager` as the internal service for workspace CRUD operations.
- Immediate persistence through `WorkspaceStore` after every successful mutation.
- In-memory workspace ownership inside `WorkspaceManager`.
- Change publishing through `onWorkspacesChanged`.
- App startup wiring so `AppEnvironment` owns a `WorkspaceManager`.

## Implemented Operations

```text
createWorkspace()
updateWorkspace()
deleteWorkspace()
duplicateWorkspace()
getWorkspace()
getAllWorkspaces()
reorderWorkspaces()
```

## Rules Implemented

- Workspace names cannot be empty.
- Duplicate names are allowed.
- Duplicate workspace IDs are rejected.
- Action IDs must be unique inside a workspace.
- Required action fields cannot be empty.
- Window layout app bundle identifiers cannot be empty.
- Window layout width and height must be positive.
- Delete requires an explicit `confirmed: true` flag.

## Save Behavior

Workspace mutations use this flow:

```text
1. Build proposed workspace list.
2. Validate proposed workspace list.
3. Save proposed list through WorkspaceStore.
4. Publish proposed list to in-memory state only after save succeeds.
```

This keeps failed saves from silently changing the app's visible workspace state.

## Acceptance Criteria Mapping

- User can create, edit, duplicate, delete, and reorder workspaces: implemented as manager operations.
- Changes are immediately saved: every mutation calls `WorkspaceStore.saveWorkspaces`.
- No duplicate IDs are created: create rejects duplicate workspace IDs, duplicate creates fresh workspace/action/layout IDs, and collection validation rejects duplicate IDs.
- Invalid workspace data is rejected: validator rejects empty names, invalid actions, duplicate action IDs, and invalid layouts.

## Verification

```text
swift build
scripts/check-workspace-models.sh
scripts/check-storage.sh
scripts/check-workspace-manager.sh
scripts/build-app.sh
plutil -lint Reopen/Resources/Info.plist
codesign --verify --deep --strict build/Reopen.app
```
