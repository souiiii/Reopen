import Foundation

enum WorkspaceRunnerCheckFailure: Error, CustomStringConvertible {
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
        throw WorkspaceRunnerCheckFailure.message(message)
    }
}

@main
enum WorkspaceRunnerChecks {
    private final class Recorder: @unchecked Sendable {
        var openedApps: [URL] = []
        var openedResources: [URL] = []
        var openedURLs: [URL] = []
        var sequence: [String] = []
    }

    private final class DelayRecorder: @unchecked Sendable {
        var delays: [TimeInterval] = []
    }

    private final class SnapshotRecorder: @unchecked Sendable {
        var snapshots: [WorkspaceLaunchProgressSnapshot] = []
    }

    private final class AsyncState: @unchecked Sendable {
        var didComplete = false
    }

    static func main() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ReopenWorkspaceRunnerChecks-\(UUID().uuidString)", isDirectory: true)
        let appURL = temporaryDirectory.appendingPathComponent("Fake.app", isDirectory: true)
        let fileURL = temporaryDirectory.appendingPathComponent("brief.txt", isDirectory: false)
        let folderURL = temporaryDirectory.appendingPathComponent("Folder", isDirectory: true)
        let projectURL = temporaryDirectory.appendingPathComponent("Project", isDirectory: true)
        let cliURL = temporaryDirectory.appendingPathComponent("code", isDirectory: false)

        defer {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }

        try FileManager.default.createDirectory(at: appURL, withIntermediateDirectories: true)
        try Data("brief".utf8).write(to: fileURL)
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: projectURL, withIntermediateDirectories: true)
        try makeExecutableFile(at: cliURL)

        try validationFailureStopsLaunch(appURL: appURL)
        try actionsRunInExpectedOrder(appURL: appURL, fileURL: fileURL, folderURL: folderURL, projectURL: projectURL, cliURL: cliURL)
        try failedActionDoesNotStopLaunch(temporaryDirectory: temporaryDirectory)
        try delaysAndLayoutResultsAreCollected(appURL: appURL)
        try progressSnapshotsArePublished(appURL: appURL, fileURL: fileURL)
        try asyncLaunchReturnsBeforeCompletion(appURL: appURL, fileURL: fileURL)

        print("Workspace runner checks passed.")
    }

    private static func validationFailureStopsLaunch(appURL: URL) throws {
        let recorder = Recorder()
        let runner = makeRunner(recorder: recorder)
        let workspace = Workspace(
            name: "Invalid",
            actions: [
                .openApp(OpenAppAction(name: "", path: appURL.path))
            ]
        )

        let result = runner.launchWorkspaceActions(in: workspace)

        try check(result.actionResults.count == 1, "Invalid action should return one validation result.")
        try check(result.actionResults[0].status == .failed, "Invalid action should fail validation.")
        try check(result.actionResults[0].errorCode == "workspace_validation_failed", "Validation failure should use workspace_validation_failed.")
        try check(recorder.openedApps.isEmpty, "Validation failure should not launch actions.")
    }

    private static func actionsRunInExpectedOrder(
        appURL: URL,
        fileURL: URL,
        folderURL: URL,
        projectURL: URL,
        cliURL: URL
    ) throws {
        let recorder = Recorder()
        let runner = makeRunner(recorder: recorder, cliURL: cliURL)
        let workspace = Workspace(
            name: "Ordered",
            actions: [
                .terminalCommand(TerminalCommandAction(name: "Dev", command: "npm run dev", workingDirectory: projectURL.path, requiresConfirmation: false)),
                .openVSCodeProject(OpenVSCodeProjectAction(projectPath: projectURL.path)),
                .openURL(OpenURLAction(url: "https://example.com")),
                .openFolder(OpenFolderAction(name: "Folder", path: folderURL.path)),
                .openFile(OpenFileAction(name: "Brief", path: fileURL.path)),
                .openApp(OpenAppAction(name: "Fake", path: appURL.path))
            ]
        )

        let result = runner.launchWorkspaceActions(in: workspace)

        try check(result.actionResults.count == 6, "Runner should report every launchable action.")
        try check(recorder.sequence == ["app", "file", "folder", "url", "code", "terminal"], "Runner should execute actions in Phase 15 order.")
        try check(result.actionResults.map(\.actionType) == [
            WorkspaceActionType.openApp.rawValue,
            WorkspaceActionType.openFile.rawValue,
            WorkspaceActionType.openFolder.rawValue,
            WorkspaceActionType.openURL.rawValue,
            WorkspaceActionType.openVSCodeProject.rawValue,
            WorkspaceActionType.terminalCommand.rawValue
        ], "Action results should follow Phase 15 order.")
    }

    private static func failedActionDoesNotStopLaunch(temporaryDirectory: URL) throws {
        let recorder = Recorder()
        let runner = makeRunner(recorder: recorder)
        let workspace = Workspace(
            name: "Continue",
            actions: [
                .openFile(OpenFileAction(name: "Missing", path: temporaryDirectory.appendingPathComponent("missing.txt").path)),
                .openURL(OpenURLAction(url: "https://example.com"))
            ]
        )

        let result = runner.launchWorkspaceActions(in: workspace)

        try check(result.actionResults.count == 2, "Runner should report failed and later successful actions.")
        try check(result.actionResults[0].status == .failed, "Missing file should fail.")
        try check(result.actionResults[1].status == .succeeded, "Later URL should still launch.")
        try check(recorder.openedURLs.map(\.absoluteString) == ["https://example.com"], "Later URL should be opened after a failure.")
    }

    private static func delaysAndLayoutResultsAreCollected(appURL: URL) throws {
        let delayRecorder = DelayRecorder()
        let layout = WindowLayout(
            appBundleIdentifier: "com.example.fake",
            windowTitle: "Fake",
            x: 0,
            y: 0,
            width: 640,
            height: 480
        )
        let runner = WorkspaceRunner(
            appLauncher: AppLauncher(openApplication: { _ in true }),
            fileFolderOpener: FileFolderOpener(openResource: { _ in true }),
            urlOpener: URLOpener(openURL: { _ in true }),
            vsCodeLauncher: VSCodeLauncher(runProcess: { _, _ in .success }),
            terminalManager: TerminalManager(
                executor: AppleScriptTerminalExecutor(executeAppleScript: { _ in .success }),
                confirmationProvider: { _, _ in true }
            ),
            windowLayoutRestorer: WindowLayoutRestorer(restoreLayouts: { layouts in
                layouts.map { layout in
                    ActionLaunchResult(
                        actionID: layout.id,
                        actionType: "windowLayout",
                        title: layout.windowTitle ?? "Window",
                        status: .succeeded,
                        message: "Restored layout."
                    )
                }
            }),
            errorLogger: ErrorLogger(),
            configuration: WorkspaceRunnerConfiguration(actionDelay: 0.25, layoutDelay: 0.75),
            sleep: { delay in delayRecorder.delays.append(delay) }
        )
        let workspace = Workspace(
            name: "Delay",
            actions: [
                .openApp(OpenAppAction(name: "Fake", path: appURL.path)),
                .openURL(OpenURLAction(url: "https://example.com")),
                .terminalCommand(TerminalCommandAction(name: "Dev", command: "pwd", workingDirectory: appURL.deletingLastPathComponent().path, requiresConfirmation: false))
            ],
            windowLayouts: [layout]
        )

        let result = runner.launchWorkspaceActions(in: workspace)

        try check(delayRecorder.delays == [0.25, 0.25, 0.75], "Runner should delay between actions and before layout restore.")
        try check(result.actionResults.count == 3, "Runner should keep action results separate.")
        try check(result.layoutResults.count == 1, "Runner should collect layout results separately.")
        try check(result.allResults.count == 4, "Combined result summary should include actions and layouts.")
    }

    private static func progressSnapshotsArePublished(appURL: URL, fileURL: URL) throws {
        let snapshotRecorder = SnapshotRecorder()
        let runner = WorkspaceRunner(
            permissionChecker: WorkspacePermissionChecker(checkPermissions: { _ in .empty }),
            appLauncher: AppLauncher(openApplication: { _ in true }),
            fileFolderOpener: FileFolderOpener(openResource: { _ in true }),
            urlOpener: URLOpener(openURL: { _ in true }),
            vsCodeLauncher: VSCodeLauncher(runProcess: { _, _ in .success }),
            terminalManager: TerminalManager(
                executor: AppleScriptTerminalExecutor(executeAppleScript: { _ in .success }),
                confirmationProvider: { _, _ in true }
            ),
            errorLogger: ErrorLogger(),
            configuration: .immediate
        )
        let workspace = Workspace(
            name: "Progress",
            actions: [
                .openApp(OpenAppAction(name: "Fake", path: appURL.path)),
                .openFile(OpenFileAction(name: "Brief", path: fileURL.path))
            ]
        )

        _ = runner.launchWorkspaceActions(in: workspace) { snapshot in
            snapshotRecorder.snapshots.append(snapshot)
        }

        try check(snapshotRecorder.snapshots.first?.stage == .validating, "Progress should start with validation.")
        try check(snapshotRecorder.snapshots.contains { $0.stage == .checkingPermissions }, "Progress should include permission checking.")
        try check(snapshotRecorder.snapshots.contains { $0.stage == .openingApps }, "Progress should include app opening.")
        try check(snapshotRecorder.snapshots.contains { $0.stage == .openingFiles }, "Progress should include file opening.")
        try check(snapshotRecorder.snapshots.last?.stage == .finished, "Progress should finish explicitly.")
        try check(snapshotRecorder.snapshots.last?.completedUnits == 2, "Finished progress should report completed action units.")
    }

    private static func asyncLaunchReturnsBeforeCompletion(appURL: URL, fileURL: URL) throws {
        let runner = WorkspaceRunner(
            appLauncher: AppLauncher(openApplication: { _ in true }),
            fileFolderOpener: FileFolderOpener(openResource: { _ in true }),
            urlOpener: URLOpener(openURL: { _ in true }),
            vsCodeLauncher: VSCodeLauncher(runProcess: { _, _ in .success }),
            terminalManager: TerminalManager(
                executor: AppleScriptTerminalExecutor(executeAppleScript: { _ in .success }),
                confirmationProvider: { _, _ in true }
            ),
            errorLogger: ErrorLogger(),
            configuration: WorkspaceRunnerConfiguration(actionDelay: 0.15, layoutDelay: 0),
            sleep: { delay in Thread.sleep(forTimeInterval: delay) }
        )
        let workspace = Workspace(
            name: "Async",
            actions: [
                .openApp(OpenAppAction(name: "Fake", path: appURL.path)),
                .openFile(OpenFileAction(name: "Brief", path: fileURL.path))
            ]
        )

        let asyncState = AsyncState()
        runner.launchWorkspaceActionsAsync(in: workspace, completion: { _ in
            asyncState.didComplete = true
        })

        try check(!asyncState.didComplete, "Async launch should return before completion.")

        let deadline = Date().addingTimeInterval(2)
        while !asyncState.didComplete && Date() < deadline {
            RunLoop.main.run(mode: .default, before: Date().addingTimeInterval(0.02))
        }

        try check(asyncState.didComplete, "Async launch should eventually complete.")
    }

    private static func makeRunner(recorder: Recorder, cliURL: URL? = nil) -> WorkspaceRunner {
        WorkspaceRunner(
            appLauncher: AppLauncher(openApplication: { url in
                recorder.openedApps.append(url)
                recorder.sequence.append("app")
                return true
            }),
            fileFolderOpener: FileFolderOpener(openResource: { url in
                recorder.openedResources.append(url)
                recorder.sequence.append(url.hasDirectoryPath ? "folder" : "file")
                return true
            }),
            urlOpener: URLOpener(openURL: { url in
                recorder.openedURLs.append(url)
                recorder.sequence.append("url")
                return true
            }),
            vsCodeLauncher: VSCodeLauncher(
                cliCandidatePaths: cliURL.map { [$0.path] } ?? [],
                appCandidatePaths: [],
                runProcess: { _, _ in
                    recorder.sequence.append("code")
                    return .success
                }
            ),
            terminalManager: TerminalManager(
                executor: AppleScriptTerminalExecutor(executeAppleScript: { _ in
                    recorder.sequence.append("terminal")
                    return .success
                }),
                confirmationProvider: { _, _ in true }
            ),
            errorLogger: ErrorLogger(),
            configuration: .immediate
        )
    }

    private static func makeExecutableFile(at url: URL) throws {
        try Data("#!/bin/sh\nexit 0\n".utf8).write(to: url)
        try FileManager.default.setAttributes(
            [.posixPermissions: NSNumber(value: Int16(0o755))],
            ofItemAtPath: url.path
        )
    }
}
