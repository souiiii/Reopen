import Foundation

@MainActor
final class AppEnvironment {
    let appState: AppState
    let windowPresenter: AppWindowPresenter
    let workspaceStore: WorkspaceStore
    let workspaceManager: WorkspaceManager
    let workspaceRunner: WorkspaceRunner
    let permissionManager: PermissionManager

    private init(
        appState: AppState,
        windowPresenter: AppWindowPresenter,
        workspaceStore: WorkspaceStore,
        workspaceManager: WorkspaceManager,
        workspaceRunner: WorkspaceRunner,
        permissionManager: PermissionManager
    ) {
        self.appState = appState
        self.windowPresenter = windowPresenter
        self.workspaceStore = workspaceStore
        self.workspaceManager = workspaceManager
        self.workspaceRunner = workspaceRunner
        self.permissionManager = permissionManager
    }

    static func bootstrap() -> AppEnvironment {
        let storageManager = StorageManager()
        let workspaceStore = WorkspaceStore(
            storageManager: storageManager,
            migrationManager: MigrationManager(),
            backupManager: JSONBackupManager(storageManager: storageManager)
        )
        let appState = AppState()
        let loadResult = workspaceStore.loadWorkspaces()
        let workspaceManager = WorkspaceManager(
            workspaceStore: workspaceStore,
            initialWorkspaces: loadResult.workspaces
        )
        let permissionManager = PermissionManager()
        let workspaceRunner = WorkspaceRunner(
            permissionChecker: WorkspacePermissionChecker(checkPermissions: { workspace in
                permissionManager.checkPermissions(for: workspace)
            }),
            appLauncher: AppLauncher(),
            fileFolderOpener: FileFolderOpener(),
            urlOpener: URLOpener(),
            vsCodeLauncher: VSCodeLauncher(),
            terminalManager: TerminalManager(),
            windowLayoutRestorer: WindowLayoutRestorer(),
            errorLogger: ErrorLogger()
        )

        workspaceManager.onWorkspacesChanged = { [appState] workspaces in
            appState.replaceWorkspaces(workspaces)
        }

        appState.replaceWorkspaces(workspaceManager.getAllWorkspaces())
        appState.storageErrorMessage = loadResult.storageError?.userFacingMessage

        return AppEnvironment(
            appState: appState,
            windowPresenter: AppWindowPresenter(),
            workspaceStore: workspaceStore,
            workspaceManager: workspaceManager,
            workspaceRunner: workspaceRunner,
            permissionManager: permissionManager
        )
    }
}
