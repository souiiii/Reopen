# Phase 2 Deliverable: Technical Architecture

## Status

Ready for Phase 3 app skeleton implementation.

This document defines where each V1 feature belongs in the Reopen codebase. It follows the Phase 2 implementation plan and keeps the product centered on one core concept:

> A workspace is a list of actions.

## Architecture Goals

- Keep Reopen a lightweight macOS menu bar app.
- Separate UI, workspace state, launch execution, persistence, permissions, and licensing.
- Keep macOS-specific integrations isolated behind focused services.
- Make action execution best-effort and observable, with per-action results.
- Keep local JSON storage stable and migration-ready.
- Avoid building future V2/V3 systems during V1.

## Proposed Swift Project Layout

The Phase 3 Xcode project should use this layout unless the generated project structure requires minor naming adjustments:

```text
Reopen/
  ReopenApp.swift
  App/
    AppDelegate.swift
    AppState.swift
    AppEnvironment.swift
  MenuBar/
    MenuBarController.swift
    MenuBarView.swift
    MenuBarCommands.swift
  Workspaces/
    Models/
      Workspace.swift
      WorkspaceAction.swift
      WindowLayout.swift
      LaunchResult.swift
    WorkspaceManager.swift
    WorkspaceValidator.swift
  WorkspaceEditor/
    WorkspaceEditorWindowController.swift
    WorkspaceEditorView.swift
    ActionListView.swift
    ActionEditorViews.swift
    Pickers/
      AppPicker.swift
      FilePicker.swift
      FolderPicker.swift
      ColorIconPicker.swift
  Runner/
    WorkspaceRunner.swift
    ActionRunner.swift
    ActionResultBuilder.swift
    AppLauncher.swift
    FileFolderOpener.swift
    URLOpener.swift
    VSCodeLauncher.swift
  Terminal/
    TerminalManager.swift
    TerminalCommandSafety.swift
    AppleScriptTerminalExecutor.swift
  Permissions/
    PermissionManager.swift
    PermissionOnboardingView.swift
    AccessibilityPermissionService.swift
    AutomationPermissionService.swift
    FileAccessService.swift
  Windows/
    WindowManager.swift
    AccessibilityWindowService.swift
    WindowLayoutCalculator.swift
  Storage/
    StorageManager.swift
    WorkspaceStore.swift
    SettingsStore.swift
    JSONBackupManager.swift
    MigrationManager.swift
    ImportExportManager.swift
  Settings/
    SettingsManager.swift
    AppSettings.swift
    SettingsView.swift
  Licensing/
    LicenseManager.swift
    LicenseState.swift
    LicenseGate.swift
  Logging/
    ErrorLogger.swift
    ReopenError.swift
    UserFacingError.swift
  Resources/
    Assets.xcassets
    Info.plist
```

## Core Modules

### App Shell

Primary files:

- `ReopenApp.swift`
- `App/AppDelegate.swift`
- `App/AppState.swift`
- `App/AppEnvironment.swift`

Responsibilities:

- Start the macOS app.
- Configure the app as a menu bar utility.
- Hide the Dock icon by default.
- Create and retain shared app services.
- Load persisted workspaces and settings on launch.
- Own top-level lifecycle actions such as quit.

Phase coverage:

- Phase 3 app skeleton.
- Phase 4 menu bar integration.
- Phase 18 settings that affect app-level behavior.

### Menu Bar Controller

Primary files:

- `MenuBar/MenuBarController.swift`
- `MenuBar/MenuBarView.swift`
- `MenuBar/MenuBarCommands.swift`

Responsibilities:

- Own the `NSStatusItem`.
- Render the dropdown menu.
- Show saved workspaces.
- Show an empty state when there are no workspaces.
- Route Create Workspace, Manage Workspaces, Settings, Quit, and Launch commands.
- Trigger `WorkspaceRunner` for one-click launch.

The menu bar controller should not directly open apps, files, folders, URLs, Terminal, or windows. It delegates launch behavior to `WorkspaceRunner`.

Phase coverage:

- Phase 4 menu bar interface.
- Phase 15 workspace launch entry point.

### Workspace Manager

Primary files:

- `Workspaces/WorkspaceManager.swift`
- `Workspaces/WorkspaceValidator.swift`
- `Workspaces/Models/Workspace.swift`
- `Workspaces/Models/WorkspaceAction.swift`
- `Workspaces/Models/WindowLayout.swift`

Responsibilities:

- Own the in-memory workspace list.
- Create, update, delete, duplicate, fetch, and reorder workspaces.
- Validate workspace names and action data.
- Ensure every workspace has a unique ID.
- Save changes through `WorkspaceStore`.
- Publish changes to the menu bar and editor UI.

Rules:

- Empty workspace names are invalid.
- Duplicate names are allowed but can be warned about in UI.
- Duplicate IDs are never allowed.
- Deleting a workspace requires UI confirmation before calling the manager.

Phase coverage:

- Phase 5 data model.
- Phase 7 workspace CRUD logic.
- Phase 8 and Phase 9 editor save flows.

### Workspace Editor

Primary files:

- `WorkspaceEditor/WorkspaceEditorWindowController.swift`
- `WorkspaceEditor/WorkspaceEditorView.swift`
- `WorkspaceEditor/ActionListView.swift`
- `WorkspaceEditor/ActionEditorViews.swift`
- picker files under `WorkspaceEditor/Pickers/`

Responsibilities:

- Create and edit workspace details.
- Add, edit, delete, and reorder actions.
- Validate forms before save.
- Use system pickers for apps, files, and folders.
- Keep unsaved edits separate from persisted workspace data.
- Save through `WorkspaceManager`.
- Cancel without mutating stored state.

The editor should not perform launch actions. It creates valid action records for the runner.

Phase coverage:

- Phase 8 workspace creation UI.
- Phase 9 workspace editing UI.
- Picker portions of Phase 10, Phase 11, Phase 12, Phase 13, and Phase 14.

### Action Runner

Primary files:

- `Runner/WorkspaceRunner.swift`
- `Runner/ActionRunner.swift`
- `Runner/ActionResultBuilder.swift`
- `Runner/AppLauncher.swift`
- `Runner/FileFolderOpener.swift`
- `Runner/URLOpener.swift`
- `Runner/VSCodeLauncher.swift`
- `Workspaces/Models/LaunchResult.swift`

Responsibilities:

- Execute a workspace in the planned V1 order:
  - validate workspace
  - check permissions
  - open apps
  - open files
  - open folders
  - open URLs
  - open code projects
  - run terminal commands
  - wait briefly
  - apply window layout
  - show launch result
- Continue after individual action failures.
- Collect success and failure results.
- Keep launch work off the main UI path where possible.
- Call specialized services for AppKit, Terminal, VS Code, and window behavior.

The runner is the central execution coordinator. It should not own persistence or editor state.

Phase coverage:

- Phase 10 app launching.
- Phase 11 file and folder opening.
- Phase 12 URL opening.
- Phase 14 VS Code support.
- Phase 15 launch engine.

### Permission Manager

Primary files:

- `Permissions/PermissionManager.swift`
- `Permissions/PermissionOnboardingView.swift`
- `Permissions/AccessibilityPermissionService.swift`
- `Permissions/AutomationPermissionService.swift`
- `Permissions/FileAccessService.swift`

Responsibilities:

- Detect Accessibility permission.
- Detect or explain Automation permission needs.
- Manage file access state for user-selected resources.
- Provide user-facing permission explanations.
- Open relevant macOS System Settings locations where possible.
- Allow partial functionality when optional permissions are denied.

The permission manager reports permission state. Feature services decide whether they can proceed, skip, or show a recoverable error.

Phase coverage:

- Phase 11 file and folder access.
- Phase 13 Terminal automation.
- Phase 16 permission onboarding.
- Phase 17 Accessibility-based window restore.

### Window Manager

Primary files:

- `Windows/WindowManager.swift`
- `Windows/AccessibilityWindowService.swift`
- `Windows/WindowLayoutCalculator.swift`
- `Workspaces/Models/WindowLayout.swift`

Responsibilities:

- Save current basic window layout for a workspace.
- Restore best-effort window positions after workspace launch.
- Support left half, right half, top half, bottom half, center, fullscreen, and custom rectangle.
- Store app bundle identifiers, optional window titles, screen identifiers, and frames.
- Skip unsupported apps and inaccessible windows.
- Report layout failures as launch results.

All product copy and errors around this module should use best-effort language.

Phase coverage:

- Phase 17 basic window layout restore.

### Terminal Manager

Primary files:

- `Terminal/TerminalManager.swift`
- `Terminal/TerminalCommandSafety.swift`
- `Terminal/AppleScriptTerminalExecutor.swift`

Responsibilities:

- Open Terminal.app.
- Run commands in a selected working directory through AppleScript.
- Escape command strings safely.
- Respect the default setting to ask before running terminal commands.
- Detect dangerous-looking commands and require confirmation.
- Report automation or command-launch failures.

Terminal command output should not be logged unless the user has explicitly opted in.

Phase coverage:

- Phase 13 terminal command execution.
- Terminal portions of Phase 15 launch engine.

### Storage Manager

Primary files:

- `Storage/StorageManager.swift`
- `Storage/WorkspaceStore.swift`
- `Storage/SettingsStore.swift`
- `Storage/JSONBackupManager.swift`
- `Storage/MigrationManager.swift`
- `Storage/ImportExportManager.swift`

Responsibilities:

- Create the Application Support directory.
- Read and write workspace JSON.
- Read and write settings.
- Create backups before overwriting workspace data.
- Handle missing files and corrupted JSON safely.
- Run lightweight data migrations.
- Import and export workspace JSON.

Storage location:

```text
~/Library/Application Support/Reopen/workspaces.json
```

Storage code should return typed errors instead of presenting UI directly.

Phase coverage:

- Phase 6 local storage.
- Phase 18 settings persistence.
- Phase 19 import and export.

### Settings Manager

Primary files:

- `Settings/SettingsManager.swift`
- `Settings/AppSettings.swift`
- `Settings/SettingsView.swift`

Responsibilities:

- Own current settings state.
- Persist settings through `SettingsStore`.
- Apply settings immediately where possible.
- Provide settings UI for:
  - launch at login
  - show or hide Dock icon
  - ask before running terminal commands
  - default launch delay
  - enable or disable window restore
  - preferred terminal app
  - preferred code editor
  - import workspaces
  - export workspaces
  - reset app data

The settings manager coordinates app behavior but does not execute launch actions directly.

Phase coverage:

- Phase 18 settings.
- Settings-backed behavior in Phase 13, Phase 15, Phase 17, and Phase 19.

### Error Logger

Primary files:

- `Logging/ErrorLogger.swift`
- `Logging/ReopenError.swift`
- `Logging/UserFacingError.swift`

Responsibilities:

- Log local diagnostic events.
- Convert technical failures into clear user-facing errors.
- Record workspace launch start, action success, action failure, permission missing, storage errors, import/export errors, and crash context where possible.
- Avoid sensitive terminal command output by default.

Errors should include:

- what failed
- likely cause
- suggested fix

Phase coverage:

- Phase 15 launch results.
- Phase 20 error handling and logging.

### License Manager

Primary files:

- `Licensing/LicenseManager.swift`
- `Licensing/LicenseState.swift`
- `Licensing/LicenseGate.swift`

Responsibilities:

- Represent free vs paid state.
- Enforce the V1 free boundary without blocking access to user data.
- Gate paid actions:
  - more than 2 workspaces
  - terminal commands
  - VS Code projects
  - layout restore
  - import/export
- Provide upgrade prompts that are clear and non-hostile.

The license manager should answer whether a feature is allowed. UI surfaces decide how to explain locked features.

Phase coverage:

- Phase 20 licensing.
- Gating hooks in Phase 7, Phase 8, Phase 13, Phase 14, Phase 17, and Phase 19.

## Data Model

The app should use `Codable` models so local JSON import/export and persistence share one model path.

### Workspace

```swift
struct Workspace: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var icon: String?
    var color: String?
    var description: String?
    var actions: [WorkspaceAction]
    var windowLayouts: [WindowLayout]
    var createdAt: Date
    var updatedAt: Date
}
```

### WorkspaceAction

Use an enum with associated values to keep action-specific data typed:

```swift
enum WorkspaceAction: Identifiable, Codable, Equatable {
    case openApp(OpenAppAction)
    case openFile(OpenFileAction)
    case openFolder(OpenFolderAction)
    case openURL(OpenURLAction)
    case terminalCommand(TerminalCommandAction)
    case openVSCodeProject(OpenVSCodeProjectAction)
    case shellScript(ShellScriptAction)
}
```

Action payloads should each carry their own stable `id`, display name, and required launch fields.

Required V1 action fields:

```text
openApp:
  id
  name
  path
  bundleIdentifier

openFile:
  id
  name
  path
  securityScopedBookmarkData?

openFolder:
  id
  name
  path
  securityScopedBookmarkData?

openURL:
  id
  url
  displayTitle?

terminalCommand:
  id
  name
  command
  workingDirectory
  requiresConfirmation

openVSCodeProject:
  id
  projectPath
  editor

shellScript:
  id
  name
  scriptPath
  workingDirectory?
  requiresConfirmation
```

### WindowLayout

```swift
struct WindowLayout: Identifiable, Codable, Equatable {
    var id: UUID
    var appBundleIdentifier: String
    var windowTitle: String?
    var screenIdentifier: String?
    var placement: WindowPlacement
    var customFrame: CGRectCodable?
}
```

`WindowPlacement` should cover:

```text
leftHalf
rightHalf
topHalf
bottomHalf
center
fullscreen
customRectangle
```

### Launch Result

```swift
struct WorkspaceLaunchResult: Codable, Equatable {
    var workspaceID: UUID
    var workspaceName: String
    var startedAt: Date
    var finishedAt: Date?
    var actionResults: [ActionLaunchResult]
    var layoutResults: [ActionLaunchResult]
}
```

Each action result should include status, user-facing message, optional underlying error code, and action ID.

## Main Data Flow

### App Launch

```text
ReopenApp
  -> AppEnvironment creates services
  -> StorageManager loads settings and workspaces
  -> WorkspaceManager publishes workspaces
  -> MenuBarController renders menu
```

### Workspace Creation or Editing

```text
MenuBarController
  -> WorkspaceEditorWindowController
  -> WorkspaceEditorView edits draft data
  -> WorkspaceValidator validates draft
  -> WorkspaceManager saves change
  -> WorkspaceStore writes JSON with backup
  -> MenuBarController refreshes workspace list
```

### Workspace Launch

```text
MenuBarController
  -> WorkspaceRunner
  -> WorkspaceValidator
  -> PermissionManager
  -> ActionRunner
      -> AppLauncher
      -> FileFolderOpener
      -> URLOpener
      -> VSCodeLauncher
      -> TerminalManager
  -> WindowManager
  -> ErrorLogger
  -> launch result UI
```

### Import and Export

```text
SettingsView or Manage Workspaces
  -> ImportExportManager
  -> WorkspaceValidator
  -> WorkspaceManager
  -> WorkspaceStore
  -> import/export summary UI
```

## Feature Ownership Map

| Feature | Owning module | Supporting modules |
| --- | --- | --- |
| App launch lifecycle | App Shell | Storage Manager, Menu Bar Controller |
| Menu bar icon and dropdown | Menu Bar Controller | Workspace Manager, Action Runner |
| Empty workspace state | Menu Bar Controller | Workspace Manager |
| Create workspace | Workspace Editor | Workspace Manager, Storage Manager, License Manager |
| Edit workspace | Workspace Editor | Workspace Manager, Storage Manager |
| Delete workspace | Workspace Manager | Workspace Editor or menu confirmation, Storage Manager |
| Duplicate workspace | Workspace Manager | Storage Manager, License Manager |
| Reorder workspaces | Workspace Manager | Storage Manager |
| Workspace JSON model | Workspace Manager | Storage Manager, Import/Export |
| App action | Action Runner | AppLauncher, Error Logger |
| File action | Action Runner | FileFolderOpener, Permission Manager, Error Logger |
| Folder action | Action Runner | FileFolderOpener, Permission Manager, Error Logger |
| URL action | Action Runner | URLOpener, Error Logger |
| Terminal command action | Terminal Manager | Action Runner, Permission Manager, Settings Manager, License Manager |
| VS Code project action | Action Runner | VSCodeLauncher, License Manager, Error Logger |
| Shell script action | Terminal Manager | Action Runner, Settings Manager, License Manager |
| Launch progress and result | Action Runner | Error Logger, Menu Bar Controller |
| Accessibility onboarding | Permission Manager | Window Manager |
| Automation onboarding | Permission Manager | Terminal Manager |
| File access | Permission Manager | Storage Manager, FileFolderOpener |
| Window layout save and restore | Window Manager | Permission Manager, Action Runner |
| Settings UI | Settings Manager | Storage Manager, App Shell |
| Import/export | Storage Manager | Workspace Manager, Workspace Validator, License Manager |
| Error messages | Error Logger | All modules |
| Local logs | Error Logger | All modules |
| Free/paid feature boundary | License Manager | Workspace Manager, Workspace Editor, Action Runner, Settings Manager |

## Dependency Rules

- UI modules can depend on managers and services through `AppEnvironment`.
- Managers can depend on storage, logging, permissions, settings, and licensing services.
- Low-level services should not depend on SwiftUI views.
- Storage should not present dialogs.
- Logging should not trigger app behavior.
- Licensing should answer entitlement questions, not mutate workspace data.
- Runner services should return structured results instead of throwing directly into UI.

## Error Handling Strategy

Use typed errors internally and user-facing error wrappers at UI boundaries.

```text
Service failure
  -> ReopenError
  -> ErrorLogger records safe diagnostic context
  -> UserFacingError explains what failed and what to try next
  -> LaunchResult or alert displays it
```

Workspace launch failures should be recoverable per action. Storage corruption, failed migrations, and reset operations require clearer blocking UI because they affect user data.

## Permission Strategy

Permissions are requested or explained only when needed:

- App, URL, and basic folder opening should work without Accessibility.
- Terminal commands need Automation permission when AppleScript controls Terminal.app.
- Window movement requires Accessibility permission.
- User-selected files and folders should preserve access using bookmarks where needed.

Denied optional permissions should disable only the affected feature and produce a clear explanation.

## Storage Strategy

V1 storage is local JSON in Application Support:

```text
~/Library/Application Support/Reopen/workspaces.json
```

Settings should be stored locally as either JSON or `UserDefaults`; use JSON if settings need export/reset symmetry, and `UserDefaults` for simple app preferences. Workspace data must remain exportable as JSON.

Before overwriting workspace data:

```text
1. Encode new data.
2. Validate encoded data can be decoded.
3. Copy current file to a timestamped backup.
4. Atomically write the new file.
5. Log success or a typed storage error.
```

## Launch Execution Order

`WorkspaceRunner` should execute in this order:

```text
1. Validate workspace.
2. Check license gates for paid actions.
3. Check relevant permissions.
4. Open apps.
5. Open files.
6. Open folders.
7. Open URLs.
8. Open VS Code projects.
9. Run terminal commands.
10. Wait for the configured launch delay.
11. Apply best-effort window layout.
12. Return launch result.
```

This order intentionally follows the implementation plan while allowing window layout to happen after windows have had time to appear.

## Boundaries for Future Features

The architecture should leave room for later support, but V1 code should not build these systems yet:

- browser extension or tab capture
- cloud sync
- shared/team workspaces
- AI suggestions
- full automation builder
- advanced tiling window manager
- iTerm, Warp, Ghostty, Kitty, Cursor, JetBrains, or other first-class integrations
- scheduled workspaces

Use protocols only where they make V1 simpler to test or where macOS APIs need a seam for replacement in tests.

## Phase 2 Acceptance Criteria

Phase 2 is complete when a developer can answer:

- App shell and lifecycle code belongs in `App/` and `ReopenApp.swift`.
- Menu bar behavior belongs in `MenuBar/`.
- Workspace CRUD and validation belong in `Workspaces/`.
- Creation and editing UI belongs in `WorkspaceEditor/`.
- Workspace launch coordination belongs in `Runner/WorkspaceRunner.swift`.
- Individual launch actions belong in focused runner services, Terminal services, or Window services.
- Permission handling belongs in `Permissions/`.
- Layout restore belongs in `Windows/`.
- Local JSON persistence, backups, migrations, and import/export belong in `Storage/`.
- Settings state and UI belong in `Settings/`.
- Error types and local logs belong in `Logging/`.
- Free/paid feature checks belong in `Licensing/`.
