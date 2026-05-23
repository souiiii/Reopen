#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT="$ROOT_DIR/.build/file-folder-opening-checks"

mkdir -p "$ROOT_DIR/.build"

swiftc \
  "$ROOT_DIR/Reopen/Workspaces/Models/Workspace.swift" \
  "$ROOT_DIR/Reopen/Workspaces/Models/WorkspaceAction.swift" \
  "$ROOT_DIR/Reopen/Workspaces/Models/WindowLayout.swift" \
  "$ROOT_DIR/Reopen/Workspaces/Models/LaunchResult.swift" \
  "$ROOT_DIR/Reopen/Workspaces/WorkspaceValidator.swift" \
  "$ROOT_DIR/Reopen/Logging/ErrorLogger.swift" \
  "$ROOT_DIR/Reopen/Runner/AppLauncher.swift" \
  "$ROOT_DIR/Reopen/Runner/FileFolderOpener.swift" \
  "$ROOT_DIR/Reopen/Runner/URLNormalizer.swift" \
  "$ROOT_DIR/Reopen/Runner/URLOpener.swift" \
  "$ROOT_DIR/Reopen/Runner/VSCodeLauncher.swift" \
  "$ROOT_DIR/Reopen/Runner/WorkspacePermissionChecker.swift" \
  "$ROOT_DIR/Reopen/Permissions/PermissionKind.swift" \
  "$ROOT_DIR/Reopen/Runner/TerminalCommandSafety.swift" \
  "$ROOT_DIR/Reopen/Runner/AppleScriptTerminalExecutor.swift" \
  "$ROOT_DIR/Reopen/Runner/TerminalManager.swift" \
  "$ROOT_DIR/Reopen/Runner/WindowLayoutRestorer.swift" \
  "$ROOT_DIR/Reopen/Runner/WorkspaceRunner.swift" \
  "$ROOT_DIR/scripts/check-file-folder-opening.swift" \
  -o "$OUTPUT"

"$OUTPUT"
