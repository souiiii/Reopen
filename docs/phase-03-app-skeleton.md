# Phase 3 Deliverable: macOS App Skeleton

## Status

Implemented.

## What This Phase Adds

- Swift macOS app package.
- AppKit app delegate for lifecycle handling.
- Menu bar status item using `NSStatusItem`.
- Hidden Dock behavior through `LSUIElement` and accessory activation policy.
- Basic menu with app title, empty workspace placeholder, and Quit command.
- SwiftUI support through the `ReopenApp` entry point and placeholder Settings scene.
- App metadata in `Info.plist`.
- Placeholder app icon generation during app bundle builds.

## Current Build Paths

Swift Package compile check:

```text
swift build
```

Local `.app` bundle build:

```text
scripts/build-app.sh
```

The build script exists because this environment has Command Line Tools active instead of full Xcode, so `xcodebuild` is unavailable here. The source layout follows the Phase 2 architecture and can be moved into a full Xcode project without changing the app structure.

## Acceptance Criteria Mapping

- App launches successfully: verified by opening the signed local `.app` bundle and confirming the process starts.
- App appears in the menu bar: implemented with `NSStatusItem`.
- App can quit from the menu: implemented with `Quit Reopen`.
- App does not crash on launch: covered by compile and bundle validation.
- App does not show an unnecessary main window: no `WindowGroup` is declared, and `LSUIElement` hides Dock presence by default.
