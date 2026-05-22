# Phase 4 Deliverable: Menu Bar Interface

## Status

Implemented.

## What This Phase Adds

- Complete menu bar dropdown structure from the implementation plan.
- `Workspaces` section header.
- Workspace rows driven by `AppState.workspaceNames`.
- Understandable empty state when no workspaces exist.
- `Create Workspace` menu item.
- `Manage Workspaces` menu item.
- `Settings` menu item.
- `Quit Reopen` menu item.
- Route handling for workspace launch, create, manage, settings, and quit.

## Current Menu Structure

```text
Reopen

Workspaces
No workspaces yet

Create Workspace
Manage Workspaces
Settings

Quit Reopen
```

When `AppState.workspaceNames` contains values, the empty state is replaced by clickable workspace rows:

```text
Reopen

Workspaces
Coding
Writing
Client A

Create Workspace
Manage Workspaces
Settings

Quit Reopen
```

## Routing Notes

This phase intentionally does not implement workspace CRUD, the workspace editor, settings persistence, or the launch engine. Those belong to later phases.

For now:

- Workspace rows open a placeholder launch route.
- `Create Workspace` opens a placeholder creation route.
- `Manage Workspaces` opens a placeholder management route.
- `Settings` opens a placeholder settings route.
- `Quit Reopen` terminates the app.

These routes provide functional targets for the Phase 4 menu items and will be replaced by the real screens and actions in later phases.

## Acceptance Criteria Mapping

- User can open the menu from the menu bar: implemented with `NSStatusItem`.
- Existing workspaces appear in the menu: implemented through `AppState.workspaceNames`.
- Empty state is understandable: implemented as `No workspaces yet`.
- Menu items trigger the correct screens or actions: Create, Manage, Settings, workspace launch placeholders, and Quit are wired.

## Verification

```text
swift build
scripts/build-app.sh
plutil -lint Reopen/Resources/Info.plist
codesign --verify --deep --strict build/Reopen.app
open -n build/Reopen.app
pgrep -x Reopen
pkill -x Reopen
```
