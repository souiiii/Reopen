import Foundation

@MainActor
final class AppEnvironment {
    let appState: AppState
    let windowPresenter: AppWindowPresenter
    let workspaceStore: WorkspaceStore
    let workspaceManager: WorkspaceManager
    let workspaceAppRunner: WorkspaceAppRunner

    private init(
        appState: AppState,
        windowPresenter: AppWindowPresenter,
        workspaceStore: WorkspaceStore,
        workspaceManager: WorkspaceManager,
        workspaceAppRunner: WorkspaceAppRunner
    ) {
        self.appState = appState
        self.windowPresenter = windowPresenter
        self.workspaceStore = workspaceStore
        self.workspaceManager = workspaceManager
        self.workspaceAppRunner = workspaceAppRunner
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
        let workspaceAppRunner = WorkspaceAppRunner(
            appLauncher: AppLauncher(),
            fileFolderOpener: FileFolderOpener(),
            urlOpener: URLOpener(),
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
            workspaceAppRunner: workspaceAppRunner
        )
    }
}
