import AppKit
import Foundation

final class TerminalManager {
    typealias ConfirmationProvider = (TerminalCommandAction, TerminalCommandSafety.Assessment) -> Bool
    typealias TerminalPreferenceProvider = @Sendable () -> PreferredTerminalApp

    private let fileManager: FileManager
    private let safety: TerminalCommandSafety
    private let executor: AppleScriptTerminalExecutor
    private let confirmationProvider: ConfirmationProvider
    private let preferredTerminalProvider: TerminalPreferenceProvider

    init(
        fileManager: FileManager = .default,
        safety: TerminalCommandSafety = TerminalCommandSafety(),
        executor: AppleScriptTerminalExecutor = AppleScriptTerminalExecutor(),
        confirmationProvider: @escaping ConfirmationProvider = TerminalManager.presentConfirmation,
        preferredTerminalProvider: @escaping TerminalPreferenceProvider = { .terminal }
    ) {
        self.fileManager = fileManager
        self.safety = safety
        self.executor = executor
        self.confirmationProvider = confirmationProvider
        self.preferredTerminalProvider = preferredTerminalProvider
    }

    func run(_ action: TerminalCommandAction) -> ActionLaunchResult {
        let title = displayTitle(for: action)
        let command = action.command.trimmingCharacters(in: .whitespacesAndNewlines)
        let workingDirectory = action.workingDirectory.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !command.isEmpty else {
            return failure(
                action: action,
                title: title,
                message: "Terminal command is empty.",
                errorCode: "empty_terminal_command"
            )
        }

        guard !workingDirectory.isEmpty else {
            return failure(
                action: action,
                title: title,
                message: "Terminal command is missing a working directory.",
                errorCode: "missing_working_directory"
            )
        }

        var isDirectory = ObjCBool(false)
        guard fileManager.fileExists(atPath: workingDirectory, isDirectory: &isDirectory), isDirectory.boolValue else {
            return failure(
                action: action,
                title: title,
                message: "Working directory could not be found at \(workingDirectory).",
                errorCode: "missing_working_directory"
            )
        }

        let assessment = safety.assess(command)
        if action.requiresConfirmation || assessment.isDangerous {
            guard confirmationProvider(action, assessment) else {
                return ActionLaunchResult(
                    actionID: action.id,
                    actionType: WorkspaceActionType.terminalCommand.rawValue,
                    title: title,
                    status: .skipped,
                    message: "Terminal command was cancelled before running.",
                    errorCode: "terminal_command_cancelled"
                )
            }
        }

        let terminalApp = preferredTerminalProvider()
        let executionResult = executor.run(
            command: command,
            workingDirectory: workingDirectory,
            terminalApp: terminalApp
        )
        guard executionResult.succeeded else {
            let errorCode = executionResult.errorCode ?? "terminal_command_failed"
            return failure(
                action: action,
                title: title,
                message: errorCode == "permission_automation_missing"
                    ? PermissionKind.automation.explanation
                    : executionResult.errorMessage ?? "Terminal could not start the command.",
                errorCode: errorCode
            )
        }

        return ActionLaunchResult(
            actionID: action.id,
            actionType: WorkspaceActionType.terminalCommand.rawValue,
            title: title,
            status: .succeeded,
            message: "Started \(title) in \(terminalApp.displayName)."
        )
    }

    private func displayTitle(for action: TerminalCommandAction) -> String {
        let name = action.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty {
            return name
        }

        let command = action.command.trimmingCharacters(in: .whitespacesAndNewlines)
        return command.isEmpty ? "Terminal Command" : command
    }

    private func failure(
        action: TerminalCommandAction,
        title: String,
        message: String,
        errorCode: String
    ) -> ActionLaunchResult {
        ActionLaunchResult(
            actionID: action.id,
            actionType: WorkspaceActionType.terminalCommand.rawValue,
            title: title,
            status: .failed,
            message: message,
            errorCode: errorCode
        )
    }

    private static func presentConfirmation(
        action: TerminalCommandAction,
        assessment: TerminalCommandSafety.Assessment
    ) -> Bool {
        if Thread.isMainThread {
            return MainActor.assumeIsolated {
                presentConfirmationAlert(action: action, assessment: assessment)
            }
        }

        var shouldRun = false
        DispatchQueue.main.sync {
            shouldRun = MainActor.assumeIsolated {
                presentConfirmationAlert(action: action, assessment: assessment)
            }
        }
        return shouldRun
    }

    @MainActor
    private static func presentConfirmationAlert(
        action: TerminalCommandAction,
        assessment: TerminalCommandSafety.Assessment
    ) -> Bool {
        let alert = NSAlert()
        alert.messageText = assessment.isDangerous ? "Run Dangerous Terminal Command?" : "Run Terminal Command?"
        alert.informativeText = confirmationMessage(for: action, assessment: assessment)
        alert.alertStyle = assessment.isDangerous ? .critical : .warning
        alert.addButton(withTitle: "Run")
        alert.addButton(withTitle: "Cancel")
        return alert.runModal() == .alertFirstButtonReturn
    }

    private static func confirmationMessage(
        for action: TerminalCommandAction,
        assessment: TerminalCommandSafety.Assessment
    ) -> String {
        var lines = [
            "Command:",
            action.command,
            "",
            "Working directory:",
            action.workingDirectory
        ]

        if assessment.isDangerous {
            lines.append("")
            lines.append("This command looks potentially destructive\(assessment.reason.map { " (\($0))" } ?? "").")
        }

        return lines.joined(separator: "\n")
    }
}
