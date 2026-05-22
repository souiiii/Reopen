import Foundation

final class WorkspaceAppRunner {
    private let appLauncher: AppLauncher
    private let errorLogger: ErrorLogger

    init(appLauncher: AppLauncher, errorLogger: ErrorLogger) {
        self.appLauncher = appLauncher
        self.errorLogger = errorLogger
    }

    func launchAppActions(in workspace: Workspace) -> WorkspaceLaunchResult {
        errorLogger.logLaunchStarted(workspace: workspace)

        var result = WorkspaceLaunchResult(
            workspaceID: workspace.id,
            workspaceName: workspace.name,
            startedAt: Date()
        )

        let appActions = workspace.actions.compactMap { action -> OpenAppAction? in
            if case .openApp(let payload) = action {
                return payload
            }

            return nil
        }

        if appActions.isEmpty {
            let skippedResult = ActionLaunchResult(
                actionType: WorkspaceActionType.openApp.rawValue,
                title: "App Launch",
                status: .skipped,
                message: "No app actions are saved in this workspace."
            )
            result.actionResults.append(skippedResult)
            errorLogger.logActionResult(skippedResult)
        } else {
            for appAction in appActions {
                let actionResult = appLauncher.launch(appAction)
                result.actionResults.append(actionResult)
                errorLogger.logActionResult(actionResult)
            }
        }

        result.finishedAt = Date()
        return result
    }
}
