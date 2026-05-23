# Reopen V1 Release Checklist

## Regression Checks

- App launches.
- Menu opens.
- Workspace creates.
- Workspace edits save.
- Workspace duplicates and deletes.
- Workspace launches.
- Settings save.
- Import/export works.
- Quit works.
- Missing apps, files, folders, invalid URLs, and missing permissions do not crash.

## Packaging Checks

- `scripts/build-app.sh` succeeds.
- `codesign --verify --deep --strict build/Reopen.app` succeeds.
- `scripts/package-release.sh` creates a `.dmg`.
- Notarization is run with `NOTARY_PROFILE` before public distribution.
- Release notes, privacy policy, terms, and download page are current.

## V1 Boundaries

- Free: 2 workspaces plus app/file/folder/URL launching.
- Paid: unlimited workspaces, terminal commands, VS Code projects, layout restore, and import/export.
- License messaging stays informative and does not destroy or lock existing user data.
