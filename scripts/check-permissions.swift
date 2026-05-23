import Foundation

enum PermissionCheckFailure: Error, CustomStringConvertible {
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
        throw PermissionCheckFailure.message(message)
    }
}

@main
enum PermissionChecks {
    private final class Recorder: @unchecked Sendable {
        var openedURLs: [URL] = []
        var terminalScripts: [String] = []
        var restoredLayoutCount = 0
        var settingsURLs: [URL] = []
    }

    static func main() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ReopenPermissionChecks-\(UUID().uuidString)", isDirectory: true)
        let fileURL = temporaryDirectory.appendingPathComponent("brief.txt", isDirectory: false)
        let folderURL = temporaryDirectory.appendingPathComponent("Folder", isDirectory: true)

        defer {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }

        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        try Data("brief".utf8).write(to: fileURL)
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)

        try accessibilityDeniedSkipsOnlyLayouts()
        try automationDeniedSkipsTerminalCommands(workingDirectory: temporaryDirectory)
        try fileAccessIssueGuidesRepairWithoutBlocking(fileURL: fileURL, folderURL: folderURL)
        try runnerWorksPartiallyWhenPermissionsAreMissing(workingDirectory: temporaryDirectory)
        try permissionSettingsLinksOpenSystemSettings()
        try terminalAutomationFailureReportsPermissionClearly(workingDirectory: temporaryDirectory)

        print("Permission checks passed.")
    }

    private static func accessibilityDeniedSkipsOnlyLayouts() throws {
        let layout = WindowLayout(
            appBundleIdentifier: "com.example.fake",
            windowTitle: "Fake",
            x: 0,
            y: 0,
            width: 640,
            height: 480
        )
        let manager = PermissionManager(
            accessibilityPermissionService: AccessibilityPermissionService(trustProvider: { false }),
            automationPermissionService: AutomationPermissionService(statusProvider: { _ in .granted }),
            fileAccessService: FileAccessService(requiresSavedBookmarks: false),
            openURL: { _ in true }
        )
        let workspace = Workspace(name: "Layout", windowLayouts: [layout])

        let report = manager.checkPermissions(for: workspace)

        try check(report.actionResults.isEmpty, "Accessibility issues should not block non-layout actions.")
        try check(report.layoutResults.count == 1, "Denied Accessibility should produce one layout result.")
        try check(report.layoutResults[0].errorCode == "permission_accessibility_missing", "Denied Accessibility should use permission_accessibility_missing.")
        try check(report.layoutResults[0].message.contains("restore window positions"), "Accessibility message should explain why it is needed.")
        try check(report.layoutResults[0].message.contains("still launch apps"), "Accessibility message should explain partial functionality.")
        try check(report.blockedLayoutIDs == [layout.id], "Denied Accessibility should block only affected layouts.")
    }

    private static func automationDeniedSkipsTerminalCommands(workingDirectory: URL) throws {
        let action = TerminalCommandAction(
            name: "Dev",
            command: "npm run dev",
            workingDirectory: workingDirectory.path,
            requiresConfirmation: false
        )
        let manager = PermissionManager(
            accessibilityPermissionService: AccessibilityPermissionService(trustProvider: { true }),
            automationPermissionService: AutomationPermissionService(statusProvider: { bundleIdentifier in
                bundleIdentifier == AutomationPermissionService.terminalBundleIdentifier ? .denied : .granted
            }),
            fileAccessService: FileAccessService(requiresSavedBookmarks: false),
            openURL: { _ in true }
        )
        let workspace = Workspace(name: "Terminal", actions: [.terminalCommand(action)])

        let report = manager.checkPermissions(for: workspace)

        try check(report.actionResults.count == 1, "Denied Automation should produce one terminal result.")
        try check(report.actionResults[0].status == .skipped, "Denied Automation should skip terminal commands.")
        try check(report.actionResults[0].errorCode == "permission_automation_denied", "Denied Automation should use permission_automation_denied.")
        try check(report.actionResults[0].message.contains("Terminal.app"), "Automation message should name Terminal.app.")
        try check(report.blockedActionIDs == [action.id], "Denied Automation should block the terminal action.")
    }

    private static func fileAccessIssueGuidesRepairWithoutBlocking(fileURL: URL, folderURL: URL) throws {
        let fileAction = OpenFileAction(name: "Brief", path: fileURL.path)
        let folderAction = OpenFolderAction(
            name: "Folder",
            path: folderURL.path,
            securityScopedBookmarkData: Data("bookmark".utf8)
        )
        let manager = PermissionManager(
            accessibilityPermissionService: AccessibilityPermissionService(trustProvider: { true }),
            automationPermissionService: AutomationPermissionService(statusProvider: { _ in .granted }),
            fileAccessService: FileAccessService(requiresSavedBookmarks: true),
            openURL: { _ in true }
        )
        let workspace = Workspace(name: "Files", actions: [
            .openFile(fileAction),
            .openFolder(folderAction)
        ])

        let report = manager.checkPermissions(for: workspace)

        try check(report.actionResults.count == 1, "Missing saved file access should produce a repair hint.")
        try check(report.actionResults[0].errorCode == "permission_file_access_missing", "File access issue should use permission_file_access_missing.")
        try check(report.actionResults[0].actionID == fileAction.id, "File access repair hint should target the affected action.")
        try check(report.blockedActionIDs.isEmpty, "File access repair hints should not block launch by themselves.")
    }

    private static func runnerWorksPartiallyWhenPermissionsAreMissing(workingDirectory: URL) throws {
        let recorder = Recorder()
        let layout = WindowLayout(
            appBundleIdentifier: "com.example.fake",
            windowTitle: "Fake",
            x: 0,
            y: 0,
            width: 640,
            height: 480
        )
        let terminalAction = TerminalCommandAction(
            name: "Dev",
            command: "npm run dev",
            workingDirectory: workingDirectory.path,
            requiresConfirmation: false
        )
        let manager = PermissionManager(
            accessibilityPermissionService: AccessibilityPermissionService(trustProvider: { false }),
            automationPermissionService: AutomationPermissionService(statusProvider: { _ in .denied }),
            fileAccessService: FileAccessService(requiresSavedBookmarks: false),
            openURL: { _ in true }
        )
        let runner = WorkspaceRunner(
            permissionChecker: WorkspacePermissionChecker(checkPermissions: { workspace in
                manager.checkPermissions(for: workspace)
            }),
            appLauncher: AppLauncher(openApplication: { _ in true }),
            fileFolderOpener: FileFolderOpener(openResource: { _ in true }),
            urlOpener: URLOpener(openURL: { url in
                recorder.openedURLs.append(url)
                return true
            }),
            vsCodeLauncher: VSCodeLauncher(runProcess: { _, _ in .success }),
            terminalManager: TerminalManager(
                executor: AppleScriptTerminalExecutor(executeAppleScript: { script in
                    recorder.terminalScripts.append(script)
                    return .success
                }),
                confirmationProvider: { _, _ in true }
            ),
            windowLayoutRestorer: WindowLayoutRestorer(restoreLayouts: { layouts in
                recorder.restoredLayoutCount += layouts.count
                return []
            }),
            errorLogger: ErrorLogger(),
            configuration: .immediate
        )
        let workspace = Workspace(
            name: "Partial",
            actions: [
                .terminalCommand(terminalAction),
                .openURL(OpenURLAction(url: "https://example.com"))
            ],
            windowLayouts: [layout]
        )

        let result = runner.launchWorkspaceActions(in: workspace)

        try check(recorder.openedURLs.map(\.absoluteString) == ["https://example.com"], "Allowed actions should still launch when optional permissions are missing.")
        try check(recorder.terminalScripts.isEmpty, "Denied Automation should prevent terminal AppleScript execution.")
        try check(recorder.restoredLayoutCount == 0, "Denied Accessibility should prevent layout restore.")
        try check(result.actionResults.contains { $0.errorCode == "permission_automation_denied" }, "Result should explain denied Automation.")
        try check(result.layoutResults.contains { $0.errorCode == "permission_accessibility_missing" }, "Result should explain missing Accessibility.")
        try check(result.actionResults.contains { $0.status == .succeeded && $0.actionType == WorkspaceActionType.openURL.rawValue }, "Result should still include successful actions.")
    }

    private static func permissionSettingsLinksOpenSystemSettings() throws {
        let recorder = Recorder()
        let manager = PermissionManager(
            openURL: { url in
                recorder.settingsURLs.append(url)
                return true
            }
        )
        let accessibilityResult = ActionLaunchResult(
            actionType: "windowLayout",
            title: "Layout",
            status: .skipped,
            message: PermissionKind.accessibility.explanation,
            errorCode: "permission_accessibility_missing"
        )
        let automationResult = ActionLaunchResult(
            actionType: WorkspaceActionType.terminalCommand.rawValue,
            title: "Terminal",
            status: .skipped,
            message: PermissionKind.automation.explanation,
            errorCode: "permission_automation_denied"
        )

        try check(manager.canOpenSettings(for: accessibilityResult), "Accessibility result should offer System Settings.")
        try check(manager.canOpenSettings(for: automationResult), "Automation result should offer System Settings.")
        try check(manager.openSettings(for: accessibilityResult), "Opening Accessibility settings should succeed through injected opener.")
        try check(manager.openSettings(for: automationResult), "Opening Automation settings should succeed through injected opener.")
        try check(recorder.settingsURLs.map(\.absoluteString).contains { $0.contains("Privacy_Accessibility") }, "Accessibility settings URL should target Accessibility privacy pane.")
        try check(recorder.settingsURLs.map(\.absoluteString).contains { $0.contains("Privacy_Automation") }, "Automation settings URL should target Automation privacy pane.")
    }

    private static func terminalAutomationFailureReportsPermissionClearly(workingDirectory: URL) throws {
        let manager = TerminalManager(
            executor: AppleScriptTerminalExecutor(executeAppleScript: { _ in
                .failure(
                    "Not authorized to send Apple events to Terminal.",
                    errorCode: "permission_automation_missing"
                )
            }),
            confirmationProvider: { _, _ in true }
        )
        let result = manager.run(TerminalCommandAction(
            name: "Dev",
            command: "npm run dev",
            workingDirectory: workingDirectory.path,
            requiresConfirmation: false
        ))

        try check(result.status == .failed, "Automation AppleScript denial should fail the terminal action.")
        try check(result.errorCode == "permission_automation_missing", "Automation AppleScript denial should use permission_automation_missing.")
        try check(result.message.contains("Automation permission"), "Automation AppleScript denial should explain the permission.")
    }
}
