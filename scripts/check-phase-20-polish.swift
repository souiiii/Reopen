import Foundation

enum Phase20CheckFailure: Error, CustomStringConvertible {
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
        throw Phase20CheckFailure.message(message)
    }
}

@main
enum Phase20PolishChecks {
    static func main() throws {
        try failureGuidanceCoversReleaseErrors()
        try localLogsAreWrittenAndSanitized()
        try licensingBoundaryIsClear()
        try releaseArtifactsExist()

        print("Phase 20 polish checks passed.")
    }

    private static func failureGuidanceCoversReleaseErrors() throws {
        let cases: [(String, String)] = [
            ("missing_app", "choose the app"),
            ("missing_file", "Repair"),
            ("missing_folder", "Repair"),
            ("invalid_url", "web address"),
            ("permission_automation_denied", "Automation"),
            ("terminal_command_failed", "working directory"),
            ("window_move_failed", "save the layout"),
            ("permission_file_access_missing", "Repair")
        ]

        for (errorCode, expectedFixText) in cases {
            let result = ActionLaunchResult(
                actionType: "check",
                title: "Check",
                status: .failed,
                message: "Failed.",
                errorCode: errorCode
            )

            guard let guidance = ActionFailureGuidanceProvider.guidance(for: result) else {
                throw Phase20CheckFailure.message("Expected guidance for \(errorCode).")
            }

            try check(!guidance.whatFailed.isEmpty, "Guidance should include what failed.")
            try check(!guidance.whyItMayHaveFailed.isEmpty, "Guidance should include why it may have failed.")
            try check(guidance.howToFix.contains(expectedFixText), "Guidance should include a useful fix for \(errorCode).")
        }
    }

    private static func localLogsAreWrittenAndSanitized() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ReopenPhase20LogChecks-\(UUID().uuidString)", isDirectory: true)
        defer {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }

        let logURL = temporaryDirectory.appendingPathComponent("reopen.log", isDirectory: false)
        let logger = ErrorLogger(localLogStore: LocalLogStore(logFileURL: logURL))

        logger.logLaunchStarted(workspace: Workspace(name: "Coding"))
        logger.logActionResult(ActionLaunchResult(
            actionType: "terminalCommand",
            title: "Dev",
            status: .failed,
            message: "Command failed\nwith details.",
            errorCode: "terminal_command_failed"
        ))

        let logText = try String(contentsOf: logURL, encoding: .utf8)

        try check(logText.contains("Workspace launch started: Coding"), "Local log should include launch starts.")
        try check(logText.contains("Action failed: Dev"), "Local log should include failed actions.")
        try check(!logText.contains("Command failed\nwith details."), "Local log should sanitize newlines.")
    }

    private static func licensingBoundaryIsClear() throws {
        let manager = LicenseManager()
        let freeWorkspace = manager.entitlement(for: .unlimitedWorkspaces, tier: .free, workspaceCount: 2)
        let paidWindowRestore = manager.entitlement(for: .windowRestore, tier: .paid)

        try check(!freeWorkspace.isAllowed, "Free plan should cap workspaces.")
        try check(freeWorkspace.message?.contains("Free includes") == true, "Free plan should explain the workspace limit.")
        try check(paidWindowRestore.isAllowed, "Paid plan should allow paid features.")
        try check(manager.planSummary(for: .paid).contains("unlimited workspaces"), "Paid summary should explain the boundary.")
    }

    private static func releaseArtifactsExist() throws {
        let rootURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let requiredPaths = [
            "scripts/package-release.sh",
            "docs/release-checklist.md",
            "docs/release-notes-v0.1.0.md",
            "docs/privacy-policy.md",
            "docs/terms.md",
            "docs/download.md"
        ]

        for path in requiredPaths {
            let url = rootURL.appendingPathComponent(path)
            try check(FileManager.default.fileExists(atPath: url.path), "Missing release artifact: \(path).")
        }
    }
}
