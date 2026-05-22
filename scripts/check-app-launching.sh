#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT="$ROOT_DIR/.build/app-launching-checks"

mkdir -p "$ROOT_DIR/.build"

swiftc \
  "$ROOT_DIR/Reopen/Workspaces/Models/Workspace.swift" \
  "$ROOT_DIR/Reopen/Workspaces/Models/WorkspaceAction.swift" \
  "$ROOT_DIR/Reopen/Workspaces/Models/WindowLayout.swift" \
  "$ROOT_DIR/Reopen/Workspaces/Models/LaunchResult.swift" \
  "$ROOT_DIR/Reopen/Logging/ErrorLogger.swift" \
  "$ROOT_DIR/Reopen/Runner/AppLauncher.swift" \
  "$ROOT_DIR/Reopen/Runner/WorkspaceAppRunner.swift" \
  "$ROOT_DIR/scripts/check-app-launching.swift" \
  -o "$OUTPUT"

"$OUTPUT"
