import Foundation

struct TerminalExecutionResult: Equatable {
    var succeeded: Bool
    var errorMessage: String?
    var errorCode: String?

    static let success = TerminalExecutionResult(succeeded: true, errorMessage: nil, errorCode: nil)

    static func failure(_ message: String, errorCode: String? = nil) -> TerminalExecutionResult {
        TerminalExecutionResult(succeeded: false, errorMessage: message, errorCode: errorCode)
    }
}

final class AppleScriptTerminalExecutor {
    typealias ExecuteAppleScript = (String) -> TerminalExecutionResult

    private let executeAppleScript: ExecuteAppleScript

    init(executeAppleScript: @escaping ExecuteAppleScript = AppleScriptTerminalExecutor.execute) {
        self.executeAppleScript = executeAppleScript
    }

    func run(command: String, workingDirectory: String) -> TerminalExecutionResult {
        let shellCommand = Self.shellCommand(command: command, workingDirectory: workingDirectory)
        let appleScript = Self.appleScript(for: shellCommand)
        return executeAppleScript(appleScript)
    }

    static func shellCommand(command: String, workingDirectory: String) -> String {
        "cd \(shellQuoted(workingDirectory)) && \(command)"
    }

    static func appleScript(for shellCommand: String) -> String {
        """
        tell application "Terminal"
            activate
            do script "\(appleScriptEscaped(shellCommand))"
        end tell
        """
    }

    static func shellQuoted(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }

    static func appleScriptEscaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\r\n", with: "; ")
            .replacingOccurrences(of: "\n", with: "; ")
            .replacingOccurrences(of: "\r", with: "; ")
    }

    private static func execute(_ source: String) -> TerminalExecutionResult {
        guard let appleScript = NSAppleScript(source: source) else {
            return .failure("Terminal AppleScript could not be created.")
        }

        var errorInfo: NSDictionary?
        _ = appleScript.executeAndReturnError(&errorInfo)

        if let errorInfo {
            let message = errorInfo[NSAppleScript.errorMessage] as? String
            return .failure(
                message ?? "Terminal AppleScript failed.",
                errorCode: permissionErrorCode(for: message)
            )
        }

        return .success
    }

    private static func permissionErrorCode(for message: String?) -> String? {
        let normalized = message?.lowercased() ?? ""
        if normalized.contains("not authorized")
            || normalized.contains("not permitted")
            || normalized.contains("not allowed") {
            return "permission_automation_missing"
        }

        return nil
    }
}
