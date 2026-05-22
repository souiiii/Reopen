# Phase 13 Deliverable: Terminal Command Execution

## Status

Implemented.

## What This Phase Adds

- Terminal command actions now run through `TerminalManager`.
- `AppleScriptTerminalExecutor` opens Terminal.app and sends a `cd <working-directory> && <command>` script.
- Working directories are shell-quoted before execution.
- AppleScript command strings escape backslashes, quotes, and line breaks before being passed to Terminal.
- Terminal actions ask before running by default.
- Users can turn off the normal confirmation per terminal action.
- Dangerous-looking commands still force a confirmation even when auto-run is enabled.
- Missing working directories and AppleScript failures are reported as launch results.

## Launch Order So Far

The runner now executes supported actions in this order:

```text
1. Apps
2. Files
3. Folders
4. URLs
5. Terminal commands
```

VS Code projects, shell scripts, and window layouts remain for later phases.

## Acceptance Criteria Mapping

- User can add a terminal command: the existing terminal action editor now includes command, working directory, folder picker, and ask-before-running controls.
- Command runs in Terminal: `AppleScriptTerminalExecutor` activates Terminal.app and starts the escaped shell command.
- Working directory is respected: executor prepends a shell-quoted `cd` before the command.
- Dangerous-looking commands show a confirmation: `TerminalCommandSafety` detects destructive patterns and forces confirmation.
- Failed commands are reported clearly: `TerminalManager` returns failed launch results for missing directories and AppleScript execution failures.

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
scripts/build-app.sh
plutil -lint Reopen/Resources/Info.plist
codesign --verify --deep --strict build/Reopen.app
```
