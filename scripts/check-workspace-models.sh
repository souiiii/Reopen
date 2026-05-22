#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT="$ROOT_DIR/.build/workspace-model-checks"

mkdir -p "$ROOT_DIR/.build"

swiftc \
  "$ROOT_DIR/Reopen/Workspaces/Models/Workspace.swift" \
  "$ROOT_DIR/Reopen/Workspaces/Models/WorkspaceAction.swift" \
  "$ROOT_DIR/Reopen/Workspaces/Models/WindowLayout.swift" \
  "$ROOT_DIR/scripts/check-workspace-models.swift" \
  -o "$OUTPUT"

"$OUTPUT"
