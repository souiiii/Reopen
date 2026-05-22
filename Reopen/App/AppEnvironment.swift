import Foundation

@MainActor
final class AppEnvironment {
    let appState: AppState
    let windowPresenter: AppWindowPresenter
    let workspaceStore: WorkspaceStore
    let workspaceManager: WorkspaceManager
    let workspaceRunner: WorkspaceRunner

    private init(
        appState: AppState,
        windowPresenter: AppWindowPresenter,
        workspaceStore: WorkspaceStore,
        workspaceManager: WorkspaceManager,
        workspaceRunner: WorkspaceRunner
    ) {
        self.appState = appState
        self.windowPresenter = windowPresenter
        self.workspaceStore = workspaceStore
        self.workspaceManager = workspaceManager
        self.workspaceRunner = workspaceRunner
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
        let workspaceRunner = WorkspaceRunner(
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
            workspaceRunner: workspaceRunner
        )
    }
}
