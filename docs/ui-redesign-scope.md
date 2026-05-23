# Reopen UI Redesign Scope

## Phase 1 Decision

The redesign is a presentation and workflow replacement, not a rewrite of Reopen's business logic.

The new primary workflow is:

```text
Menu bar icon -> unified workspace panel -> create/edit/delete/launch inline
```

Reopen should move away from a plain menu that opens several separate workflow windows. The app should behave like a compact workspace hub anchored to the menu bar.

## Current Entry Points

### Menu Bar Dropdown

Current implementation:

- `MenuBarController` owns an `NSStatusItem`.
- `MenuBarController.rebuildMenu()` builds a standard `NSMenu`.
- Workspace rows are raw text `NSMenuItem` entries.
- Clicking a workspace menu item starts launch and opens progress/result windows.
- Create, Manage, Settings, and Quit are separate menu items.

Redesign status:

- Replace as the primary UI.
- Keep temporarily behind the Phase 2 feature flag while the unified panel is incomplete.
- The status item itself stays; its click target should open the new panel.

### Create Workspace Window

Current implementation:

- `AppWindowPresenter.showWorkspaceCreation(...)`
- `WorkspaceEditorWindowController`
- `WorkspaceEditorView`
- `WorkspaceCreationDraft`
- action pickers and action editor views

Redesign status:

- Replace as a normal user flow.
- Creation should happen inline inside the unified workspace panel.
- Reuse draft/action conversion logic where practical.
- Native pickers for app/file/folder/project selection should remain usable.

### Manage Workspaces Window

Current implementation:

- `AppWindowPresenter.showWorkspaceManagement(...)`
- `ManageWorkspacesWindowController`
- `ManageWorkspacesView`
- edit/export/create callbacks into `WorkspaceManager` and `SettingsManager`

Redesign status:

- Replace for core workspace management.
- Workspace list, edit, delete, duplicate, reorder, and per-workspace actions should live in the unified panel.
- Import/export and rare utility actions may move to settings or a quiet footer/more menu later.

### Launch Progress Window

Current implementation:

- `AppWindowPresenter.showLaunchProgress(...)`
- `LaunchProgressWindowController`
- `LaunchProgressView`
- fed by `WorkspaceRunner.launchWorkspaceActionsAsync(...)` progress snapshots

Redesign status:

- Replace as the default launch feedback surface.
- Progress should be shown quietly on the workspace card.
- Keep launch progress models and runner progress callbacks.

### Launch Result Window

Current implementation:

- `AppWindowPresenter.showLaunchResult(...)`
- `LaunchResultWindowController`
- `LaunchResultView`
- uses `ActionFailureGuidanceProvider`
- supports file/folder repair and permission settings actions

Redesign status:

- Replace as the default result surface.
- Success should be subtle and temporary.
- Failures should appear inline with details and repair actions.
- Keep result models, failure guidance, permission handling, and repair behavior.

### Settings Window

Current implementation:

- `AppWindowPresenter.showSettings(...)`
- `SettingsWindowController`
- `SettingsView`
- `SettingsManager`

Redesign status:

- Keep as a separate secondary utility window for now.
- Settings is not part of the frequent workspace launch/create/edit loop.
- The unified panel should expose Settings calmly in the footer.

### Onboarding Window

Current implementation:

- `AppDelegate` shows onboarding on first launch when no workspaces exist.
- `AppWindowPresenter.showOnboarding(...)`
- `OnboardingWindowController`
- `OnboardingView`

Redesign status:

- Not a primary target of the 18-phase redesign.
- Later phases may update onboarding copy or route "Create Workspace" into the unified panel instead of the old create window.

## Systems To Reuse

The following systems are stable and should remain the source of truth:

- Workspace models: `Workspace`, `WorkspaceAction`, `WindowLayout`, `LaunchResult`
- Workspace persistence: `StorageManager`, `WorkspaceStore`, `SettingsStore`, `MigrationManager`, backups
- Workspace operations: `WorkspaceManager`
- Workspace validation: `WorkspaceValidator`, with Phase 9 planned for optional names and auto naming
- Launch execution: `WorkspaceRunner`, `AppLauncher`, `FileFolderOpener`, `URLOpener`, `TerminalManager`, `VSCodeLauncher`, `WindowLayoutRestorer`
- Permissions: `PermissionManager`, permission services, permission result models
- Settings: `AppSettings`, `SettingsManager`, `SettingsRuntime`
- Import/export: `WorkspaceImportExportManager`
- Failure guidance and repair support: `ActionFailureGuidanceProvider`, `AppWindowPresenter` repair helpers until moved inline
- Licensing boundaries: `LicenseManager`
- Logging: `ErrorLogger`

## Replacement Boundary

Replace the workflow shell:

- raw `NSMenu` workspace list
- separate create workspace window as the normal create path
- separate manage workspaces window as the normal management path
- separate launch progress window as the normal progress path
- separate launch result window as the normal result path

Do not rewrite:

- saved workspace schema
- persistence format
- launch ordering and execution behavior
- permission checks
- terminal safety confirmation behavior
- import/export semantics
- license entitlement rules
- existing repair semantics

## Development Constraint

Phase 2 must add a safe toggle so the old menu/window flow remains available while the new unified panel is built. The old controllers may stay temporarily for fallback/debugging, but normal users should be routed through the unified panel by Phase 18.
