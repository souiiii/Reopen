# Phase 5 Deliverable: Workspace Data Model

## Status

Implemented.

## What This Phase Adds

- `Workspace` model with:
  - `id`
  - `name`
  - optional `icon`
  - optional `color`
  - optional `description`
  - `actions`
  - `windowLayouts`
  - `createdAt`
  - `updatedAt`
- `WorkspaceAction` enum with the V1 action types from the implementation plan:
  - `openApp`
  - `openFile`
  - `openFolder`
  - `openURL`
  - `terminalCommand`
  - `openVSCodeProject`
  - `shellScript`
- Typed action payload structs for each action type.
- `WindowLayout` model with:
  - `appBundleIdentifier`
  - `windowTitle`
  - `screenIdentifier`
  - `x`
  - `y`
  - `width`
  - `height`
- Focused model checks for JSON round-trip behavior and invalid action type rejection.

## Encoding Format

Workspace actions encode with a stable `type` discriminator:

```json
{
  "id": "55555555-5555-5555-5555-555555555555",
  "type": "openURL",
  "url": "https://github.com/example/project",
  "displayTitle": "GitHub"
}
```

This keeps persisted JSON readable and gives future phases a single safe place to add new action cases.

## Acceptance Criteria Mapping

- Workspace can be encoded to JSON: covered by `workspaceRoundTripsThroughJSON`.
- Workspace can be decoded from JSON: covered by `workspaceRoundTripsThroughJSON` and `oldWorkspaceJSONWithKnownActionTypeDecodes`.
- Invalid action types are rejected safely: unknown `type` values throw `DecodingError.dataCorrupted`.
- Future action types can be added without breaking old workspaces: action decoding uses stable raw string discriminators, and existing action JSON remains decodable as new cases are added.

## Verification

```text
swift build
scripts/check-workspace-models.sh
```
