# Phase 17 Deliverable: Basic Window Layout Restore

## Status

Implemented.

## What This Phase Adds

- Window services under `Windows/`:
  - `AccessibilityWindowService`
  - `WindowManager`
  - `WindowLayoutCalculator`
  - `WindowFrame`
- `WindowLayoutRestorer` now uses the real `WindowManager` instead of the Phase 15 placeholder.
- Workspaces now store `isWindowRestoreEnabled` so best-effort window restore can be disabled per workspace.
- `WindowLayout` now stores a `placement` with V1 options:
  - Left Half
  - Right Half
  - Top Half
  - Bottom Half
  - Center
  - Fullscreen
  - Custom Rectangle
- The workspace editor includes a best-effort window restore section with:
  - enable/disable toggle
  - save current layout button
  - saved window list
  - placement picker per saved window
  - remove saved window action
- Accessibility capture reads open windows and stores app bundle ID, title, screen identifier, and frame.
- Restore applies saved or calculated frames after workspace launch.
- Unsupported or inaccessible windows produce failed layout results instead of crashing.

## Best-Effort Behavior

Window restore intentionally uses best-effort language. macOS apps can expose windows differently, some windows cannot be moved, and multi-monitor setups can change between saves and restores.

When a saved screen is unavailable, Reopen chooses the nearest available screen or falls back to the main screen. When a custom rectangle no longer fits, it is clamped into the visible screen frame.

## Acceptance Criteria Mapping

- User can save current layout for a workspace: workspace editor has a Save Current Layout button backed by `WindowManager.captureCurrentLayout`.
- Reopen can move supported app windows: `AccessibilityWindowService` sets AX position and size attributes.
- Unsupported apps do not crash the app: restore errors become failed layout results.
- User sees layout restore failures clearly: layout failures are included in launch result summaries.
- Layout restore can be disabled per workspace: `Workspace.isWindowRestoreEnabled` disables permission checks and restore attempts.

## Verification

```text
swift build
scripts/check-workspace-models.sh
scripts/check-storage.sh
scripts/check-workspace-manager.sh
scripts/check-workspace-creation.sh
scripts/check-workspace-editing.sh
scripts/check-app-launching.sh
scripts/check-file-folder-opening.sh
scripts/check-url-opening.sh
scripts/check-terminal-command.sh
scripts/check-vscode-project.sh
scripts/check-workspace-runner.sh
scripts/check-permissions.sh
scripts/check-window-layout.sh
scripts/build-app.sh
plutil -lint Reopen/Resources/Info.plist
codesign --verify --deep --strict build/Reopen.app
```
