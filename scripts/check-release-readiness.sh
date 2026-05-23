#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

checks=(
  "scripts/check-workspace-models.sh"
  "scripts/check-storage.sh"
  "scripts/check-workspace-manager.sh"
  "scripts/check-workspace-creation.sh"
  "scripts/check-workspace-editing.sh"
  "scripts/check-app-launching.sh"
  "scripts/check-file-folder-opening.sh"
  "scripts/check-url-opening.sh"
  "scripts/check-terminal-command.sh"
  "scripts/check-vscode-project.sh"
  "scripts/check-workspace-runner.sh"
  "scripts/check-permissions.sh"
  "scripts/check-window-layout.sh"
  "scripts/check-settings.sh"
  "scripts/check-import-export.sh"
  "scripts/check-phase-20-polish.sh"
)

cd "$ROOT_DIR"
swift build

for check_script in "${checks[@]}"; do
  "$ROOT_DIR/$check_script"
done

"$ROOT_DIR/scripts/build-app.sh" >/dev/null
plutil -lint "$ROOT_DIR/Reopen/Resources/Info.plist"
codesign --verify --deep --strict "$ROOT_DIR/build/Reopen.app"

required_docs=(
  "docs/release-checklist.md"
  "docs/release-notes-v0.1.0.md"
  "docs/privacy-policy.md"
  "docs/terms.md"
  "docs/download.md"
)

for path in "${required_docs[@]}"; do
  test -s "$ROOT_DIR/$path"
done

echo "Release readiness checks passed."
