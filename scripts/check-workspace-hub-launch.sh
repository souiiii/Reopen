#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT="$ROOT_DIR/.build/workspace-hub-launch-checks"

mkdir -p "$ROOT_DIR/.build"

swiftc \
  "$ROOT_DIR/Reopen/Workspaces/Models/Workspace.swift" \
  "$ROOT_DIR/Reopen/Workspaces/Models/WorkspaceAction.swift" \
  "$ROOT_DIR/Reopen/Workspaces/Models/WindowLayout.swift" \
  "$ROOT_DIR/Reopen/Workspaces/Models/LaunchResult.swift" \
  "$ROOT_DIR/Reopen/Runner/URLNormalizer.swift" \
  "$ROOT_DIR/Reopen/WorkspaceEditor/WorkspaceCreationDraft.swift" \
  "$ROOT_DIR/Reopen/WorkspaceHub/WorkspaceHubState.swift" \
  "$ROOT_DIR/scripts/check-workspace-hub-launch.swift" \
  -o "$OUTPUT"

"$OUTPUT"
