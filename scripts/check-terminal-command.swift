import Foundation

enum TerminalCommandCheckFailure: Error, CustomStringConvertible {
    case message(String)

    var description: String {
        switch self {
        case .message(let message):
            return message
        }
    }
}

func check(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() {
        throw TerminalCommandCheckFailure.message(message)
    }
}

@main
enum TerminalCommandChecks {
    static func main() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ReopenTerminalCommandChecks-\(UUID().uuidString)", isDirectory: true)
        let quotedDirectory = temporaryDirectory.appendingPathComponent("Project's App", isDirectory: true)

        defer {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }

        try FileManager.default.createDirectory(at: quotedDirectory, withIntermediateDirectories: true)

        try terminalDraftDefaultsToAskBeforeRunning(workingDirectory: quotedDirectory)
        try terminalDraftPersistsConfirmationChoice(workingDirectory: quotedDirectory)
        try terminalCommandRespectsWorkingDirectory(workingDirectory: quotedDirectory)
        try safeCommandCanRunWithoutConfirmation(workingDirectory: quotedDirectory)
        try dangerousCommandAlwaysRequiresConfirmation(workingDirectory: quotedDirectory)
        try missingWorkingDirectoryFailsClearly(temporaryDirectory: temporaryDirectory)
        try executorFailureIsReported(workingDirectory: quotedDirectory)
        try workspaceRunnerContinuesAfterTerminalFailure(workingDirectory: quotedDirectory, temporaryDirectory: temporaryDirectory)

        print("Terminal command checks passed.")
    }

    private static func terminalDraftDefaultsToAskBeforeRunning(workingDirectory: URL) throws {
        var draft = WorkspaceActionDraft.terminalCommand()
        draft.command = "npm run dev"
        draft.workingDirectory = workingDirectory.path

        guard case .terminalCommand(let action) = try draft.makeWorkspaceAction() else {
            throw TerminalCommandCheckFailure.message("Expected terminal command action.")
        }

        try check(action.requiresConfirmation, "Terminal command drafts should ask before running by default.")
    }

    private static func terminalDraftPersistsConfirmationChoice(workingDirectory: URL) throws {
        var draft = WorkspaceActionDraft.terminalCommand()
        draft.command = "npm run dev"
        draft.workingDirectory = workingDirectory.path
        draft.requiresConfirmation = false

        guard case .terminalCommand(let action) = try draft.makeWorkspaceAction() else {
            throw TerminalCommandCheckFailure.message("Expected terminal command action.")
        }

        let editDraft = WorkspaceActionDraft(action: .terminalCommand(action))

        try check(!action.requiresConfirmation, "Saved terminal commands should preserve ask-before-running choice.")
        try check(!editDraft.requiresConfirmation, "Editing a terminal command should preserve ask-before-running choice.")
    }

    private static func terminalCommandRespectsWorkingDirectory(workingDirectory: URL) throws {
        var scripts: [String] = []
        let manager = TerminalManager(
            executor: AppleScriptTerminalExecutor(executeAppleScript: { script in
                scripts.append(script)
                return .success
            }),
            confirmationProvider: { _, _ in true }
        )
        let result = manager.run(TerminalCommandAction(
            name: "Dev Server",
            command: #"printf "hello""#,
            workingDirectory: workingDirectory.path,
            requiresConfirmation: false
        ))

        let expectedShellCommand = AppleScriptTerminalExecutor.shellCommand(
            command: #"printf "hello""#,
            workingDirectory: workingDirectory.path
        )

        try check(result.status == .succeeded, "Valid terminal command should start successfully.")
        try check(scripts.count == 1, "Terminal executor should receive one AppleScript.")
        try check(scripts[0].contains(AppleScriptTerminalExecutor.appleScriptEscaped(expectedShellCommand)), "AppleScript should cd into the selected working directory before running the command.")
        try check(scripts[0].contains(#"printf \"hello\""#), "AppleScript should escape command quotes safely.")
    }

    private static func safeCommandCanRunWithoutConfirmation(workingDirectory: URL) throws {
        var confirmationCount = 0
        let manager = TerminalManager(
            executor: AppleScriptTerminalExecutor(executeAppleScript: { _ in .success }),
            confirmationProvider: { _, _ in
                confirmationCount += 1
                return true
            }
        )
        let result = manager.run(TerminalCommandAction(
            name: "List",
            command: "ls",
            workingDirectory: workingDirectory.path,
            requiresConfirmation: false
        ))

        try check(result.status == .succeeded, "Safe command with explicit auto-run should succeed.")
        try check(confirmationCount == 0, "Safe command should run without confirmation when user allowed auto-run.")
    }

    private static func dangerousCommandAlwaysRequiresConfirmation(workingDirectory: URL) throws {
        var confirmationCount = 0
        var executedScripts: [String] = []
        let manager = TerminalManager(
            executor: AppleScriptTerminalExecutor(executeAppleScript: { script in
                executedScripts.append(script)
                return .success
            }),
            confirmationProvider: { _, assessment in
                confirmationCount += 1
                return !assessment.isDangerous
            }
        )
        let result = manager.run(TerminalCommandAction(
            name: "Delete",
            command: "rm -rf build",
            workingDirectory: workingDirectory.path,
            requiresConfirmation: false
        ))

        try check(confirmationCount == 1, "Dangerous-looking commands should ask even when auto-run is allowed.")
        try check(result.status == .skipped, "Cancelled dangerous command should be skipped.")
        try check(result.errorCode == "terminal_command_cancelled", "Cancelled dangerous command should use terminal_command_cancelled.")
        try check(executedScripts.isEmpty, "Cancelled dangerous command should not execute AppleScript.")
    }

    private static func missingWorkingDirectoryFailsClearly(temporaryDirectory: URL) throws {
        let manager = TerminalManager(
            executor: AppleScriptTerminalExecutor(executeAppleScript: { _ in .success }),
            confirmationProvider: { _, _ in true }
        )
        let result = manager.run(TerminalCommandAction(
            name: "Missing",
            command: "pwd",
            workingDirectory: temporaryDirectory.appendingPathComponent("Missing").path,
            requiresConfirmation: false
        ))

        try check(result.status == .failed, "Missing working directory should fail.")
        try check(result.errorCode == "missing_working_directory", "Missing working directory should use missing_working_directory.")
    }

    private static func executorFailureIsReported(workingDirectory: URL) throws {
        let manager = TerminalManager(
            executor: AppleScriptTerminalExecutor(executeAppleScript: { _ in
                .failure("Terminal is unavailable.")
            }),
            confirmationProvider: { _, _ in true }
        )
        let result = manager.run(TerminalCommandAction(
            name: "Unavailable",
            command: "pwd",
            workingDirectory: workingDirectory.path,
            requiresConfirmation: false
        ))

        try check(result.status == .failed, "Executor failure should fail the terminal action.")
        try check(result.errorCode == "terminal_command_failed", "Executor failure should use terminal_command_failed.")
        try check(result.message == "Terminal is unavailable.", "Executor failure message should be reported clearly.")
    }

    private static func workspaceRunnerContinuesAfterTerminalFailure(
        workingDirectory: URL,
        temporaryDirectory: URL
    ) throws {
        var executedScripts: [String] = []
        let runner = WorkspaceAppRunner(
            appLauncher: AppLauncher(openApplication: { _ in true }),
            fileFolderOpener: FileFolderOpener(openResource: { _ in true }),
            urlOpener: URLOpener(openURL: { _ in true }),
            vsCodeLauncher: VSCodeLauncher(runProcess: { _, _ in .success }),
            terminalManager: TerminalManager(
                executor: AppleScriptTerminalExecutor(executeAppleScript: { script in
                    executedScripts.append(script)
                    return .success
                }),
                confirmationProvider: { _, _ in true }
            ),
            errorLogger: ErrorLogger()
        )
        let workspace = Workspace(
            name: "Terminal",
            actions: [
                .terminalCommand(TerminalCommandAction(
                    name: "Missing",
                    command: "pwd",
                    workingDirectory: temporaryDirectory.appendingPathComponent("Missing").path,
                    requiresConfirmation: false
                )),
                .terminalCommand(TerminalCommandAction(
                    name: "Present",
                    command: "pwd",
                    workingDirectory: workingDirectory.path,
                    requiresConfirmation: false
                ))
            ]
        )

        let result = runner.launchWorkspaceActions(in: workspace)

        try check(result.actionResults.count == 2, "Runner should report every terminal action.")
        try check(result.actionResults[0].status == .failed, "Missing terminal working directory should fail.")
        try check(result.actionResults[1].status == .succeeded, "Runner should continue to later terminal command.")
        try check(executedScripts.count == 1, "Only valid terminal commands should execute AppleScript.")
    }
}
