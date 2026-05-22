# Phase 12 Deliverable: URL Opening

## Status

Implemented.

## What This Phase Adds

- URL normalization and validation through `URLNormalizer`.
- Automatic `https://` prefixing when a user enters a domain without a scheme.
- Rejection of invalid URLs and unsupported schemes.
- `URLOpener` for opening links in the default browser through `NSWorkspace`.
- URL actions in workspace launch results.
- Multiple URL actions per workspace.
- Domain fallback display when a URL has no custom display title.

## Launch Order So Far

The runner now executes supported actions in this order:

```text
1. Apps
2. Files
3. Folders
4. URLs
```

Terminal commands, VS Code projects, and window layouts remain for later phases.

## Acceptance Criteria Mapping

- User can add valid URLs: URL action input already exists, and draft conversion now normalizes and validates before saving.
- Invalid URLs are rejected: `URLNormalizer` rejects empty, malformed, and unsupported-scheme URLs.
- Workspace launch opens URLs in the default browser: `URLOpener` opens normalized URLs with `NSWorkspace`.
- Multiple URLs open reliably: `WorkspaceAppRunner` executes every URL action and records per-action results.

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
scripts/build-app.sh
plutil -lint Reopen/Resources/Info.plist
codesign --verify --deep --strict build/Reopen.app
```
