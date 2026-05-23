#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! rg -Fq "defaultUseUnifiedWorkspacePanel" "$ROOT_DIR/Reopen/App/AppFeatureFlags.swift"; then
  echo "Missing unified workspace panel feature flag default."
  exit 1
fi

if ! rg -Fq "#if REOPEN_USE_LEGACY_MENU_BAR" "$ROOT_DIR/Reopen/App/AppFeatureFlags.swift"; then
  echo "Legacy menu bar route should be limited to the explicit compile-time flag."
  exit 1
fi

if rg -Fq "showWorkspaceCreation(" "$ROOT_DIR/Reopen/App/AppDelegate.swift"; then
  echo "AppDelegate should not route first-run onboarding to the old create window."
  exit 1
fi

if ! rg -Fq "showCreateWorkspaceEntryPoint" "$ROOT_DIR/Reopen/App/AppDelegate.swift"; then
  echo "First-run onboarding should open the unified workspace panel create flow."
  exit 1
fi

if ! rg -Fq "showCreateComposer(relativeTo" "$ROOT_DIR/Reopen/WorkspaceHub/WorkspaceHubPanelController.swift"; then
  echo "Workspace hub should expose an inline create entry point."
  exit 1
fi

if ! rg -Fq "state.startCreating()" "$ROOT_DIR/Reopen/WorkspaceHub/WorkspaceHubPanelController.swift"; then
  echo "Inline create entry point should start the create composer."
  exit 1
fi

if ! rg -Fq "showLaunchResult(" "$ROOT_DIR/Reopen/MenuBar/MenuBarController.swift"; then
  echo "Legacy launch-result route missing from fallback menu; fallback/debug route may have been deleted unexpectedly."
  exit 1
fi

if ! rg -Fq "guard environment.featureFlags.useUnifiedWorkspacePanel else" "$ROOT_DIR/Reopen/MenuBar/MenuBarController.swift"; then
  echo "Create workspace entry point should preserve legacy fallback behind the feature flag."
  exit 1
fi

echo "Workspace hub production route checks passed."
