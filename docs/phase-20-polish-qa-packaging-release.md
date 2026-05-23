# Phase 20 Deliverable: Professional Polish, QA, Packaging, and Release

## Status

Implemented.

## What This Phase Adds

- Clear failure guidance for launch results:
  - what failed
  - why it may have failed
  - how the user can fix it
- Local diagnostic logging for:
  - app launch and termination
  - workspace launch start
  - action success, failure, and skips
  - permission missing
  - storage errors
  - import/export errors
- Terminal command output is not logged unless the user enables it in Settings.
- Polished empty states for:
  - menu bar with no workspaces
  - Manage Workspaces with no workspaces
  - workspace editor with no actions
- First-run onboarding screen.
- Settings privacy and license sections.
- Simple direct-sale licensing boundary:
  - Free: 2 workspaces plus app/file/folder/URL launching
  - Paid: unlimited workspaces, terminal commands, VS Code projects, layout restore, and import/export
- Release packaging support:
  - signed app build
  - DMG creation
  - optional notarization through `NOTARY_PROFILE`
- Release documents:
  - release checklist
  - release notes
  - privacy policy
  - terms
  - download page

## Acceptance Criteria Mapping

- Error handling: launch result failures now display recovery guidance.
- Logging: `ErrorLogger` writes local sanitized logs and uses unified logging.
- Empty states: menu, workspace management, and action editor have clearer empty states.
- UI polish: result rows use status icons, onboarding is available, settings include privacy/license copy.
- Testing: `scripts/check-release-readiness.sh` runs the full release validation stack.
- Packaging: `scripts/package-release.sh` builds a signed `.app`, creates a `.dmg`, and notarizes when configured.
- Licensing: `LicenseManager` defines the V1 free/paid feature boundary without destructive enforcement.

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
scripts/check-settings.sh
scripts/check-import-export.sh
scripts/check-phase-20-polish.sh
scripts/check-release-readiness.sh
scripts/build-app.sh
scripts/package-release.sh
plutil -lint Reopen/Resources/Info.plist
codesign --verify --deep --strict build/Reopen.app
```
