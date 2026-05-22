# Phase 10 Deliverable: App Launching

## Status

Implemented.

## What This Phase Adds

- `AppLauncher` for opening saved `.app` bundle actions through `NSWorkspace`.
- Missing app detection before launch.
- Invalid app path detection for non-`.app` paths.
- Launch failure reporting when macOS does not open the app.
- `WorkspaceAppRunner` for executing saved app actions from a workspace.
- Launch result models for per-action success, failure, and skipped states.
- Launch result window that shows what happened.
- Basic launch logging through `ErrorLogger`.
- Workspace menu clicks now launch saved app actions instead of opening a placeholder.

## Existing Phase 8 Support Used Here

- The app picker uses `NSOpenPanel`.
- The picker is restricted to application bundles.
- App actions store:
  - app name
  - app path
  - bundle identifier when available

## Scope Boundary

Phase 10 only executes `openApp` actions. File, folder, URL, terminal, VS Code, and window layout actions remain for later phases.

## Acceptance Criteria Mapping

- User can add an app to a workspace: implemented through the existing app picker and `OpenAppAction` model.
- Workspace launch opens the selected app: workspace menu clicks now call `WorkspaceAppRunner.launchAppActions`.
- Missing apps are handled gracefully: `AppLauncher` returns a failed launch result with `missing_app`.
- App launch failures are logged and shown in launch results: `ErrorLogger` logs results and `LaunchResultView` displays them.

## Verification

```text
swift build
scripts/check-workspace-models.sh
scripts/check-storage.sh
scripts/check-workspace-manager.sh
scripts/check-workspace-creation.sh
scripts/check-workspace-editing.sh
scripts/check-app-launching.sh
scripts/build-app.sh
plutil -lint Reopen/Resources/Info.plist
codesign --verify --deep --strict build/Reopen.app
```
