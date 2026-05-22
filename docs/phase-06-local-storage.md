# Phase 6 Deliverable: Local Storage

## Status

Implemented.

## What This Phase Adds

- Application Support storage at:

```text
~/Library/Application Support/Reopen/workspaces.json
```

- `StorageManager` to own storage paths and create directories.
- `WorkspaceStore` to load and save workspace JSON.
- `JSONBackupManager` to back up existing workspace data before overwriting.
- `MigrationManager` with schema-versioned storage envelope support.
- Legacy `[Workspace]` JSON decoding so older simple workspace arrays can still load.
- Typed `StorageError` values with user-facing messages.
- App launch loading through `AppEnvironment.bootstrap()`.
- Menu bar surfacing for storage errors through `AppState.storageErrorMessage`.

## Storage Format

V1 writes a schema-versioned envelope:

```json
{
  "schemaVersion": 1,
  "workspaces": []
}
```

The loader also accepts a legacy root array:

```json
[]
```

This gives V1 lightweight migration support without making storage more complex than needed.

## Backup Behavior

Before overwriting an existing `workspaces.json`, Reopen copies the current file into:

```text
~/Library/Application Support/Reopen/backups/
```

The backup filename includes the original file name and a timestamp.

## Acceptance Criteria Mapping

- Workspaces persist after app restart: `WorkspaceStore.saveWorkspaces` writes JSON and `loadWorkspaces` reloads it.
- Corrupted JSON does not crash the app: load failures return an empty list plus a typed storage error.
- App creates a backup before destructive writes: `JSONBackupManager.createBackupIfNeeded` runs before overwriting existing workspace data.
- Storage errors are shown clearly to the user: `StorageError.userFacingMessage` is stored on `AppState` and rendered in the menu.

## Verification

```text
swift build
scripts/check-workspace-models.sh
scripts/check-storage.sh
scripts/build-app.sh
plutil -lint Reopen/Resources/Info.plist
codesign --verify --deep --strict build/Reopen.app
```
