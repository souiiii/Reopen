import Foundation

enum SettingsCheckFailure: Error, CustomStringConvertible {
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
        throw SettingsCheckFailure.message(message)
    }
}

@MainActor
private final class RecordingLaunchAtLoginService: LaunchAtLoginManaging {
    var updates: [Bool] = []

    func setLaunchAtLoginEnabled(_ enabled: Bool) throws {
        updates.append(enabled)
    }
}

@MainActor
private final class RecordingDockIconService: DockIconManaging {
    var updates: [Bool] = []

    func setDockIconVisible(_ visible: Bool) {
        updates.append(visible)
    }
}

@MainActor
@main
enum SettingsChecks {
    static func main() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ReopenSettingsChecks-\(UUID().uuidString)", isDirectory: true)

        defer {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }

        let storageManager = StorageManager(applicationSupportDirectory: temporaryDirectory)
        let backupManager = JSONBackupManager(storageManager: storageManager)
        let settingsStore = SettingsStore(storageManager: storageManager, backupManager: backupManager)
        let workspaceStore = WorkspaceStore(
            storageManager: storageManager,
            migrationManager: MigrationManager(),
            backupManager: backupManager
        )
        let workspaceManager = WorkspaceManager(workspaceStore: workspaceStore)

        try settingsPersistAfterRestart(settingsStore: settingsStore)
        try managerAppliesAndPublishesSettings(settingsStore: settingsStore)
        try importExportAndResetWorkspaces(
            settingsStore: settingsStore,
            workspaceManager: workspaceManager,
            temporaryDirectory: temporaryDirectory
        )
        try launchDefaultsAffectRunner()
        try preferredTerminalIsUsedByExecutor()

        print("Settings checks passed.")
    }

    private static func settingsPersistAfterRestart(settingsStore: SettingsStore) throws {
        let settings = AppSettings(
            launchAtLogin: true,
            showDockIcon: true,
            askBeforeRunningTerminalCommands: false,
            defaultLaunchDelay: 0.35,
            enableWindowRestore: false,
            preferredTerminalApp: .iTerm,
            preferredCodeEditor: .visualStudioCodeInsiders
        )

        try settingsStore.saveSettings(settings)
        let result = settingsStore.loadSettings()

        try check(result.storageError == nil, "Saved settings should reload without a storage error.")
        try check(result.settings == settings, "Settings should persist after reload.")
    }

    private static func managerAppliesAndPublishesSettings(settingsStore: SettingsStore) throws {
        let runtime = SettingsRuntime(settings: AppSettings())
        let loginService = RecordingLaunchAtLoginService()
        let dockService = RecordingDockIconService()
        let manager = SettingsManager(
            settings: AppSettings(),
            settingsStore: settingsStore,
            runtime: runtime,
            launchAtLoginService: loginService,
            dockIconService: dockService
        )

        manager.setLaunchAtLogin(true)
        manager.setShowDockIcon(true)
        manager.setAskBeforeRunningTerminalCommands(false)
        manager.setDefaultLaunchDelay(0.42)
        manager.setEnableWindowRestore(false)
        manager.setPreferredTerminalApp(.iTerm)
        manager.setPreferredCodeEditor(.visualStudioCodeInsiders)

        try check(loginService.updates == [true], "Launch-at-login changes should be applied immediately.")
        try check(dockService.updates == [true], "Dock icon changes should be applied immediately.")
        try check(runtime.settings == manager.settings, "Runtime settings should mirror published settings.")
        try check(!runtime.settings.askBeforeRunningTerminalCommands, "Terminal prompt setting should update runtime settings.")
        try check(runtime.settings.defaultLaunchDelay == 0.42, "Launch delay should update runtime settings.")
        try check(!runtime.settings.enableWindowRestore, "Window restore setting should update runtime settings.")
    }

    private static func importExportAndResetWorkspaces(
        settingsStore: SettingsStore,
        workspaceManager: WorkspaceManager,
        temporaryDirectory: URL
    ) throws {
        let runtime = SettingsRuntime(settings: AppSettings())
        let manager = SettingsManager(
            settings: AppSettings(),
            settingsStore: settingsStore,
            runtime: runtime,
            launchAtLoginService: RecordingLaunchAtLoginService(),
            dockIconService: RecordingDockIconService()
        )
        let workspace = Workspace(
            name: "Imported",
            actions: [
                .openURL(OpenURLAction(url: "https://example.com", displayTitle: "Example"))
            ]
        )
        _ = try workspaceManager.createWorkspace(workspace)

        let exportURL = temporaryDirectory.appendingPathComponent("workspaces-export.json", isDirectory: false)
        manager.exportWorkspaces(from: workspaceManager, to: exportURL)

        try check(manager.errorMessage == nil, "Export should not produce a settings error.")
        try check(FileManager.default.fileExists(atPath: exportURL.path), "Export should write a JSON file.")

        manager.resetAppData(workspaceManager: workspaceManager, confirmed: false)
        try check(manager.errorMessage == SettingsManagerError.resetRequiresConfirmation.userFacingMessage, "Reset should require confirmation.")

        manager.resetAppData(workspaceManager: workspaceManager, confirmed: true)
        try check(workspaceManager.getAllWorkspaces().isEmpty, "Confirmed reset should clear workspaces.")
        try check(manager.settings == AppSettings(), "Confirmed reset should restore default settings.")

        manager.importWorkspaces(from: exportURL, into: workspaceManager, confirmed: false)
        try check(manager.errorMessage == SettingsManagerError.importRequiresConfirmation.userFacingMessage, "Import should require confirmation.")

        manager.importWorkspaces(from: exportURL, into: workspaceManager, confirmed: true)
        try check(manager.errorMessage == nil, "Confirmed import should not leave an error message.")
        try check(workspaceManager.getAllWorkspaces() == [workspace], "Confirmed import should add workspace data.")
    }

    private static func launchDefaultsAffectRunner() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ReopenSettingsRunnerChecks-\(UUID().uuidString)", isDirectory: true)
        defer {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }

        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)

        final class DelayRecorder: @unchecked Sendable {
            var delays: [TimeInterval] = []
        }
        final class ConfirmationRecorder: @unchecked Sendable {
            var count = 0
        }

        let delayRecorder = DelayRecorder()
        let confirmationRecorder = ConfirmationRecorder()
        let layout = WindowLayout(
            appBundleIdentifier: "com.example.fake",
            x: 0,
            y: 0,
            width: 400,
            height: 300
        )
        let runner = WorkspaceRunner(
            permissionChecker: WorkspacePermissionChecker(checkPermissions: { _ in .empty }),
            appLauncher: AppLauncher(openApplication: { _ in true }),
            fileFolderOpener: FileFolderOpener(openResource: { _ in true }),
            urlOpener: URLOpener(openURL: { _ in true }),
            vsCodeLauncher: VSCodeLauncher(runProcess: { _, _ in .success }),
            terminalManager: TerminalManager(
                executor: AppleScriptTerminalExecutor(executeAppleScript: { _ in .success }),
                confirmationProvider: { _, _ in
                    confirmationRecorder.count += 1
                    return true
                }
            ),
            windowLayoutRestorer: WindowLayoutRestorer(restoreLayouts: { layouts in
                layouts.map { layout in
                    ActionLaunchResult(
                        actionID: layout.id,
                        actionType: "windowLayout",
                        title: "Window",
                        status: .succeeded,
                        message: "Restored layout."
                    )
                }
            }),
            errorLogger: ErrorLogger(),
            configuration: .immediate,
            launchDelayProvider: { 0.4 },
            terminalConfirmationPreferenceProvider: { true },
            windowRestorePreferenceProvider: { false },
            sleep: { delay in delayRecorder.delays.append(delay) }
        )
        let workspace = Workspace(
            name: "Launch Defaults",
            actions: [
                .openURL(OpenURLAction(url: "https://example.com")),
                .terminalCommand(TerminalCommandAction(
                    name: "Safe",
                    command: "pwd",
                    workingDirectory: temporaryDirectory.path,
                    requiresConfirmation: false
                ))
            ],
            windowLayouts: [layout]
        )

        let result = runner.launchWorkspaceActions(in: workspace)

        try check(delayRecorder.delays == [0.4], "Default launch delay should be used between launch actions.")
        try check(confirmationRecorder.count == 1, "Global terminal safety setting should force confirmation.")
        try check(result.layoutResults.isEmpty, "Global window restore setting should disable layout restoration.")
    }

    private static func preferredTerminalIsUsedByExecutor() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ReopenSettingsTerminalChecks-\(UUID().uuidString)", isDirectory: true)
        defer {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }

        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)

        var scripts: [String] = []
        let manager = TerminalManager(
            executor: AppleScriptTerminalExecutor(executeAppleScript: { script in
                scripts.append(script)
                return .success
            }),
            confirmationProvider: { _, _ in true },
            preferredTerminalProvider: { .iTerm }
        )
        let result = manager.run(TerminalCommandAction(
            name: "Dev",
            command: "pwd",
            workingDirectory: temporaryDirectory.path,
            requiresConfirmation: false
        ))

        try check(result.status == .succeeded, "Preferred terminal run should succeed.")
        try check(result.message.contains("iTerm"), "Terminal result should name the preferred terminal app.")
        try check(scripts.first?.contains("tell application \"iTerm\"") == true, "AppleScript should target the preferred terminal app.")
    }
}
