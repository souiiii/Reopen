# Phase 1 Deliverable: Frozen V1 Scope

## Status

Frozen for V1 implementation.

This document converts the product specification and implementation plan into the build boundary for Reopen V1. Later phases should implement within this boundary unless the scope is explicitly revised.

## Product Goal

Reopen V1 is a local-first macOS menu bar utility that lets a user create named workspaces and launch a saved work setup in one click.

The product promise for V1 is:

> Launch your work setup in one click.

The product must not promise perfect restoration of every app, tab, or window state.

## V1 Must Include

### App Shell

- Native macOS app built with Swift, SwiftUI, and AppKit where needed.
- Menu bar utility behavior.
- Hidden Dock icon by default.
- Quit action from the menu.
- App metadata: name, bundle identifier, version, and placeholder app icon.

### Menu Bar Experience

- Menu bar icon.
- Dropdown menu with saved workspaces.
- Empty state when no workspaces exist.
- Create Workspace entry.
- Manage Workspaces entry.
- Settings entry.
- Quit entry.
- One-click workspace launch from the menu.

### Workspace Management

- Create workspace.
- Edit workspace.
- Delete workspace with confirmation.
- Duplicate workspace.
- Reorder workspaces.
- Workspace details:
  - name
  - optional icon
  - optional color
  - optional description
  - launch actions
  - optional window layouts
- Workspace names cannot be empty.
- Duplicate workspace names are allowed but should not be encouraged.
- Every workspace must have a unique ID.

### Workspace Actions

- Open macOS apps.
- Open files in their default apps.
- Open folders in Finder.
- Open URLs in the default browser.
- Run Terminal.app commands.
- Open project folders in Visual Studio Code.
- Support simple shell script actions only if they fit the same safety model as terminal commands.

### Launch Engine

- Validate the selected workspace before launch.
- Execute actions in a predictable order:
  - apps
  - files
  - folders
  - URLs
  - code projects
  - terminal commands
  - window layout restore
- Continue launching remaining actions if one action fails.
- Collect per-action success and failure results.
- Show a launch progress or result view.
- Keep the app responsive during launch.

### Local Storage

- Store workspaces locally as JSON.
- Use Application Support storage:

```text
~/Library/Application Support/Reopen/workspaces.json
```

- Load workspaces on app launch.
- Save changes immediately after workspace mutations.
- Handle missing storage files.
- Handle corrupted JSON without crashing.
- Create a backup before overwriting workspace data.
- Include lightweight migration support for future model changes.

### Import and Export

- Export all workspaces to JSON.
- Export individual workspaces to JSON.
- Import workspace JSON.
- Validate imported files before saving.
- Regenerate duplicate imported workspace IDs.
- Show a clear import summary.
- Reject invalid imports safely.

### Settings

- Launch Reopen at login.
- Show or hide Dock icon.
- Ask before running terminal commands.
- Default launch delay.
- Enable or disable window restore.
- Preferred terminal app, with Terminal.app as the V1 implementation target.
- Preferred code editor, with Visual Studio Code as the V1 implementation target.
- Import workspaces.
- Export workspaces.
- Reset app data with confirmation.

### Permissions

- Accessibility permission flow for window movement and resizing.
- Automation permission flow for Terminal.app control.
- File access handling for user-selected files and folders.
- Clear explanation of why each permission is needed.
- Partial functionality when optional permissions are denied.
- Buttons or guidance to open the relevant macOS System Settings area.

### Window Layout Restore

- Best-effort layout restore only.
- Save and restore basic window positions where macOS Accessibility APIs allow it.
- Supported V1 layout targets:
  - left half
  - right half
  - top half
  - bottom half
  - center
  - fullscreen
  - custom rectangle
- Store enough layout data to identify the app and target frame.
- Skip unsupported or unavailable windows without crashing.
- Report layout restore failures clearly.
- Allow layout restore to be disabled per workspace or globally.

### Error Handling and Logging

- Clear errors for:
  - missing app
  - missing file
  - missing folder
  - invalid URL
  - permission denied
  - terminal command failure
  - window move failure
  - storage failure
  - import failure
  - automation failure
- Errors should explain what failed, likely cause, and possible fix.
- Local logs for debugging.
- Do not log sensitive terminal command output unless the user opts in.

### Licensing Boundary

- Free tier:
  - up to 2 workspaces
  - app, file, folder, and URL launching
- Paid tier:
  - unlimited workspaces
  - terminal commands
  - VS Code projects
  - layout restore
  - import and export
- Licensing must not block local data access or make the app feel hostile.

### Release Readiness

- Basic QA checklist for workspace CRUD, launch actions, permissions, storage, import/export, and layout restore.
- Release build prepared for direct distribution outside the Mac App Store.
- Code signing and notarization.
- DMG packaging.
- Release notes.
- Privacy policy.
- Terms page.

## V1 Must Not Include

- Cloud sync.
- User accounts.
- Team sharing.
- Shared workspaces.
- Enterprise administration.
- Browser extension.
- Deep browser tab/session management.
- Perfect tab restoration.
- Full session snapshotting.
- AI workspace suggestions or generation.
- Complex automation builder.
- Advanced tiling window manager.
- Full replacement for Rectangle, Moom, Magnet, Aerospace, Keyboard Maestro, Raycast, Alfred, Shortcuts, or Hazel.
- Mobile app.
- Windows support.
- Linux support.
- Mac App Store subscription system.
- iCloud sync.
- Scheduled workspaces.
- Workspace templates.
- Raycast extension.
- Shortcuts integration.
- Per-workspace wallpapers.
- Per-workspace notification settings.

## V1 Assumptions

- Distribution is a direct download DMG, not Mac App Store distribution.
- Storage is local JSON, not a database and not cloud-backed storage.
- Default browser handling is sufficient for V1.
- Terminal.app is the only terminal that must be supported in V1.
- Visual Studio Code is the only code editor that must receive first-class V1 project support.
- Window layout restore is allowed to be imperfect and best-effort.
- The app can work partially when Accessibility or Automation permissions are denied.
- The user owns and manages their own local workspace data.

## Phase 1 Acceptance Criteria

Phase 1 is complete when the team can clearly answer:

- What belongs in Reopen V1?
- What is intentionally excluded from Reopen V1?
- What product promise is safe to make?
- What technical assumptions should later phases follow?
- What features require special caution because of permissions, safety, or imperfect macOS control?

## Implementation Guidance for Later Phases

- Build in the order defined by the implementation plan.
- Treat workspace actions as the core product primitive.
- Keep the app local-first and menu-bar-first.
- Prefer graceful degradation over hard failure.
- Make terminal execution opt-in or confirmation-gated by default.
- Use best-effort language for layout restore everywhere in the UI.
- Avoid expanding V1 scope when implementing future phases.
