#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT="$ROOT_DIR/.build/phase-20-polish-checks"

mkdir -p "$ROOT_DIR/.build"

swiftc \
  "$ROOT_DIR/Reopen/Workspaces/Models/Workspace.swift" \
  "$ROOT_DIR/Reopen/Workspaces/Models/WorkspaceAction.swift" \
  "$ROOT_DIR/Reopen/Workspaces/Models/WindowLayout.swift" \
  "$ROOT_DIR/Reopen/Workspaces/Models/LaunchResult.swift" \
  "$ROOT_DIR/Reopen/Diagnostics/ActionFailureGuidance.swift" \
  "$ROOT_DIR/Reopen/Logging/ErrorLogger.swift" \
  "$ROOT_DIR/Reopen/Licensing/LicenseManager.swift" \
  "$ROOT_DIR/scripts/check-phase-20-polish.swift" \
  -o "$OUTPUT"

"$OUTPUT"
