# Phase 16 Deliverable: Permission Onboarding

## Status

Implemented.

## What This Phase Adds

- Permission services under `Permissions/`:
  - `AccessibilityPermissionService`
  - `AutomationPermissionService`
  - `FileAccessService`
  - `PermissionManager`
  - `PermissionOnboardingView`
- Permission checks now run only when the workspace needs the affected feature.
- Accessibility is checked when a workspace has saved window layouts.
- Automation is checked when a workspace has terminal command actions.
- File access is checked for saved file and folder actions that do not have saved bookmark access.
- Missing optional permissions produce clear launch results instead of silent failures.
- Launch results now include permission onboarding rows with System Settings buttons for Accessibility and Automation.
- File access issues guide the user to repair the affected file or folder action.
- `NSAppleEventsUsageDescription` was added for Terminal automation permission prompts.

## Partial Functionality

Missing permissions block only the affected feature:

```text
Accessibility denied -> window layout restore is skipped
Automation denied -> terminal commands are skipped
File access missing -> affected file/folder can be repaired, other actions continue
```

Apps, files, folders, URLs, and VS Code projects can still launch when window layout permissions are missing.

## Acceptance Criteria Mapping

- User understands why permissions are needed: permission results explain the feature that needs the permission and what still works.
- App does not fail silently because of missing permissions: permission issues are included in launch results.
- App works without layout features if Accessibility is denied: layout IDs are blocked while other launch actions continue.
- App guides user to the right macOS settings screen: Accessibility and Automation onboarding open the matching System Settings privacy pane.

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
scripts/build-app.sh
plutil -lint Reopen/Resources/Info.plist
codesign --verify --deep --strict build/Reopen.app
```
