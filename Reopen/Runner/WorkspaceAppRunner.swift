import Foundation

final class WorkspaceAppRunner {
    private let appLauncher: AppLauncher
    private let fileFolderOpener: FileFolderOpener
    private let urlOpener: URLOpener
    private let errorLogger: ErrorLogger

    init(
        appLauncher: AppLauncher,
        fileFolderOpener: FileFolderOpener,
        urlOpener: URLOpener,
        errorLogger: ErrorLogger
    ) {
        self.appLauncher = appLauncher
        self.fileFolderOpener = fileFolderOpener
        self.urlOpener = urlOpener
        self.errorLogger = errorLogger
    }

    func launchWorkspaceActions(in workspace: Workspace) -> WorkspaceLaunchResult {
        errorLogger.logLaunchStarted(workspace: workspace)

        var result = WorkspaceLaunchResult(
            workspaceID: workspace.id,
            workspaceName: workspace.name,
            startedAt: Date()
        )

        var didRunLaunchableAction = false

        for appAction in appActions(in: workspace) {
            didRunLaunchableAction = true
            append(appLauncher.launch(appAction), to: &result)
        }

        for fileAction in fileActions(in: workspace) {
            didRunLaunchableAction = true
            append(fileFolderOpener.openFile(fileAction), to: &result)
        }

        for folderAction in folderActions(in: workspace) {
            didRunLaunchableAction = true
            append(fileFolderOpener.openFolder(folderAction), to: &result)
        }

        for urlAction in urlActions(in: workspace) {
            didRunLaunchableAction = true
            append(urlOpener.open(urlAction), to: &result)
        }

        if !didRunLaunchableAction {
            let skippedResult = ActionLaunchResult(
                actionType: "workspace",
                title: "Workspace Launch",
                status: .skipped,
                message: "No app, file, folder, or URL actions are saved in this workspace."
            )
            append(skippedResult, to: &result)
        }

        result.finishedAt = Date()
        return result
    }

    func launchAppActions(in workspace: Workspace) -> WorkspaceLaunchResult {
        launchWorkspaceActions(in: workspace)
    }

    private func append(_ actionResult: ActionLaunchResult, to result: inout WorkspaceLaunchResult) {
        result.actionResults.append(actionResult)
        errorLogger.logActionResult(actionResult)
    }

    private func appActions(in workspace: Workspace) -> [OpenAppAction] {
        workspace.actions.compactMap { action in
            if case .openApp(let payload) = action {
                return payload
            }

            return nil
        }
    }

    private func fileActions(in workspace: Workspace) -> [OpenFileAction] {
        workspace.actions.compactMap { action in
            if case .openFile(let payload) = action {
                return payload
            }

            return nil
        }
    }

    private func folderActions(in workspace: Workspace) -> [OpenFolderAction] {
        workspace.actions.compactMap { action in
            if case .openFolder(let payload) = action {
                return payload
            }

            return nil
        }
    }

    private func urlActions(in workspace: Workspace) -> [OpenURLAction] {
        workspace.actions.compactMap { action in
            if case .openURL(let payload) = action {
                return payload
            }

            return nil
        }
    }
}
