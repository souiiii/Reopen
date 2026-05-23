import Foundation

@MainActor
final class AppEnvironment {
    let appState: AppState
    let windowPresenter: AppWindowPresenter
    let workspaceStore: WorkspaceStore
    let settingsStore: SettingsStore
    let workspaceManager: WorkspaceManager
    let workspaceRunner: WorkspaceRunner
    let permissionManager: PermissionManager
    let settingsManager: SettingsManager

    private init(
        appState: AppState,
        windowPresenter: AppWindowPresenter,
        workspaceStore: WorkspaceStore,
        settingsStore: SettingsStore,
        workspaceManager: WorkspaceManager,
        workspaceRunner: WorkspaceRunner,
        permissionManager: PermissionManager,
        settingsManager: SettingsManager
    ) {
        self.appState = appState
        self.windowPresenter = windowPresenter
        self.workspaceStore = workspaceStore
        self.settingsStore = settingsStore
        self.workspaceManager = workspaceManager
        self.workspaceRunner = workspaceRunner
        self.permissionManager = permissionManager
        self.settingsManager = settingsManager
    }

    static func bootstrap() -> AppEnvironment {
        let storageManager = StorageManager()
        let backupManager = JSONBackupManager(storageManager: storageManager)
        let workspaceStore = WorkspaceStore(
            storageManager: storageManager,
            migrationManager: MigrationManager(),
            backupManager: backupManager
        )
        let settingsStore = SettingsStore(
            storageManager: storageManager,
            backupManager: backupManager
        )
        let appState = AppState()
        let loadResult = workspaceStore.loadWorkspaces()
        let settingsLoadResult = settingsStore.loadSettings()
        let settingsRuntime = SettingsRuntime(settings: settingsLoadResult.settings)
        let settingsManager = SettingsManager(
            settings: settingsLoadResult.settings,
            settingsStore: settingsStore,
            runtime: settingsRuntime
        )
        let workspaceManager = WorkspaceManager(
            workspaceStore: workspaceStore,
            initialWorkspaces: loadResult.workspaces
        )
        let permissionManager = PermissionManager()
        let workspaceRunner = WorkspaceRunner(
            permissionChecker: WorkspacePermissionChecker(checkPermissions: { workspace in
                var effectiveWorkspace = workspace
                if !settingsRuntime.settings.enableWindowRestore {
                    effectiveWorkspace.isWindowRestoreEnabled = false
                }

                return permissionManager.checkPermissions(for: effectiveWorkspace)
            }),
            appLauncher: AppLauncher(),
            fileFolderOpener: FileFolderOpener(),
            urlOpener: URLOpener(),
            vsCodeLauncher: VSCodeLauncher(preferredEditorProvider: {
                settingsRuntime.settings.preferredCodeEditor
            }),
            terminalManager: TerminalManager(preferredTerminalProvider: {
                settingsRuntime.settings.preferredTerminalApp
            }),
            windowLayoutRestorer: WindowLayoutRestorer(),
            errorLogger: ErrorLogger(),
            launchDelayProvider: {
                settingsRuntime.settings.defaultLaunchDelay
            },
            terminalConfirmationPreferenceProvider: {
                settingsRuntime.settings.askBeforeRunningTerminalCommands
            },
            windowRestorePreferenceProvider: {
                settingsRuntime.settings.enableWindowRestore
            }
        )

        workspaceManager.onWorkspacesChanged = { [appState] workspaces in
            appState.replaceWorkspaces(workspaces)
        }

        appState.replaceWorkspaces(workspaceManager.getAllWorkspaces())
        appState.storageErrorMessage = loadResult.storageError?.userFacingMessage
            ?? settingsLoadResult.storageError?.userFacingMessage
        settingsManager.applyCurrentSettings()

        return AppEnvironment(
            appState: appState,
            windowPresenter: AppWindowPresenter(),
            workspaceStore: workspaceStore,
            settingsStore: settingsStore,
            workspaceManager: workspaceManager,
            workspaceRunner: workspaceRunner,
            permissionManager: permissionManager,
            settingsManager: settingsManager
        )
    }
}
