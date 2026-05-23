#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT="$ROOT_DIR/.build/workspace-hub-edit-checks"

mkdir -p "$ROOT_DIR/.build"

swiftc \
  "$ROOT_DIR/Reopen/App/AppState.swift" \
  "$ROOT_DIR/Reopen/Workspaces/Models/Workspace.swift" \
  "$ROOT_DIR/Reopen/Workspaces/Models/WorkspaceAction.swift" \
  "$ROOT_DIR/Reopen/Workspaces/Models/WindowLayout.swift" \
  "$ROOT_DIR/Reopen/Workspaces/Models/LaunchResult.swift" \
  "$ROOT_DIR/Reopen/Storage/StorageError.swift" \
  "$ROOT_DIR/Reopen/Storage/StorageManager.swift" \
  "$ROOT_DIR/Reopen/Storage/JSONBackupManager.swift" \
  "$ROOT_DIR/Reopen/Storage/MigrationManager.swift" \
  "$ROOT_DIR/Reopen/Storage/WorkspaceStore.swift" \
  "$ROOT_DIR/Reopen/Workspaces/WorkspaceNameGenerator.swift" \
  "$ROOT_DIR/Reopen/Workspaces/WorkspaceValidator.swift" \
  "$ROOT_DIR/Reopen/Workspaces/WorkspaceManager.swift" \
  "$ROOT_DIR/Reopen/Runner/URLNormalizer.swift" \
  "$ROOT_DIR/Reopen/WorkspaceEditor/WorkspaceCreationDraft.swift" \
  "$ROOT_DIR/Reopen/WorkspaceHub/WorkspaceHubState.swift" \
  "$ROOT_DIR/Reopen/WorkspaceHub/WorkspaceHubEditCoordinator.swift" \
  "$ROOT_DIR/scripts/check-workspace-hub-edit.swift" \
  -o "$OUTPUT"

"$OUTPUT"
