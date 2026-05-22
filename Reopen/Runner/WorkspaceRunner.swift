import Foundation

struct WorkspaceRunnerConfiguration: Equatable {
    var actionDelay: TimeInterval
    var layoutDelay: TimeInterval

    static let live = WorkspaceRunnerConfiguration(actionDelay: 0.05, layoutDelay: 0.5)
    static let immediate = WorkspaceRunnerConfiguration(actionDelay: 0, layoutDelay: 0)
}

final class WorkspaceRunner: @unchecked Sendable {
    typealias ProgressHandler = @Sendable (WorkspaceLaunchProgressSnapshot) -> Void
    typealias CompletionHandler = @Sendable (WorkspaceLaunchResult) -> Void
    typealias SleepHandler = @Sendable (TimeInterval) -> Void

    private let workspaceValidator: WorkspaceValidator
    private let permissionChecker: WorkspacePermissionChecker
    private let appLauncher: AppLauncher
    private let fileFolderOpener: FileFolderOpener
    private let urlOpener: URLOpener
    private let vsCodeLauncher: VSCodeLauncher
    private let terminalManager: TerminalManager
    private let windowLayoutRestorer: WindowLayoutRestorer
    private let errorLogger: ErrorLogger
    private let configuration: WorkspaceRunnerConfiguration
    private let sleep: SleepHandler

    init(
        workspaceValidator: WorkspaceValidator = WorkspaceValidator(),
        permissionChecker: WorkspacePermissionChecker = WorkspacePermissionChecker(),
        appLauncher: AppLauncher,
        fileFolderOpener: FileFolderOpener,
        urlOpener: URLOpener,
        vsCodeLauncher: VSCodeLauncher,
        terminalManager: TerminalManager,
        windowLayoutRestorer: WindowLayoutRestorer = WindowLayoutRestorer(),
        errorLogger: ErrorLogger,
        configuration: WorkspaceRunnerConfiguration = .live,
        sleep: @escaping SleepHandler = { interval in
            guard interval > 0 else {
                return
            }

            Thread.sleep(forTimeInterval: interval)
        }
    ) {
        self.workspaceValidator = workspaceValidator
        self.permissionChecker = permissionChecker
        self.appLauncher = appLauncher
        self.fileFolderOpener = fileFolderOpener
        self.urlOpener = urlOpener
        self.vsCodeLauncher = vsCodeLauncher
        self.terminalManager = terminalManager
        self.windowLayoutRestorer = windowLayoutRestorer
        self.errorLogger = errorLogger
        self.configuration = configuration
        self.sleep = sleep
    }

    func launchWorkspaceActions(
        in workspace: Workspace,
        progressHandler: ProgressHandler? = nil
    ) -> WorkspaceLaunchResult {
        errorLogger.logLaunchStarted(workspace: workspace)

        var result = WorkspaceLaunchResult(
            workspaceID: workspace.id,
            workspaceName: workspace.name,
            startedAt: Date()
        )

        let totalActionCount = launchableActionCount(in: workspace)
        let totalUnitCount = max(totalActionCount + workspace.windowLayouts.count, 1)
        var completedUnits = 0

        publishProgress(
            workspace: workspace,
            stage: .validating,
            message: "Validating workspace...",
            result: result,
            completedUnits: completedUnits,
            totalUnits: totalUnitCount,
            progressHandler: progressHandler
        )

        do {
            try workspaceValidator.validateWorkspace(workspace)
        } catch let error as WorkspaceValidationError {
            append(workspaceValidationFailure(workspace: workspace, message: error.userFacingMessage), to: &result)
            completedUnits = totalUnitCount
            result.finishedAt = Date()
            publishProgress(
                workspace: workspace,
                stage: .finished,
                message: "Workspace launch failed validation.",
                result: result,
                completedUnits: completedUnits,
                totalUnits: totalUnitCount,
                progressHandler: progressHandler
            )
            return result
        } catch {
            append(workspaceValidationFailure(workspace: workspace, message: "Workspace could not be validated."), to: &result)
            completedUnits = totalUnitCount
            result.finishedAt = Date()
            publishProgress(
                workspace: workspace,
                stage: .finished,
                message: "Workspace launch failed validation.",
                result: result,
                completedUnits: completedUnits,
                totalUnits: totalUnitCount,
                progressHandler: progressHandler
            )
            return result
        }

        publishProgress(
            workspace: workspace,
            stage: .checkingPermissions,
            message: "Checking permissions...",
            result: result,
            completedUnits: completedUnits,
            totalUnits: totalUnitCount,
            progressHandler: progressHandler
        )

        for permissionResult in permissionChecker.check(workspace) {
            append(permissionResult, to: &result)
        }

        for appAction in appActions(in: workspace) {
            append(appLauncher.launch(appAction), to: &result)
            completedUnits += 1
            publishAndDelayIfNeeded(
                workspace: workspace,
                stage: .openingApps,
                message: "Opening apps...",
                result: result,
                completedUnits: completedUnits,
                totalUnits: totalUnitCount,
                totalActionCount: totalActionCount,
                progressHandler: progressHandler
            )
        }

        for fileAction in fileActions(in: workspace) {
            append(fileFolderOpener.openFile(fileAction), to: &result)
            completedUnits += 1
            publishAndDelayIfNeeded(
                workspace: workspace,
                stage: .openingFiles,
                message: "Opening files...",
                result: result,
                completedUnits: completedUnits,
                totalUnits: totalUnitCount,
                totalActionCount: totalActionCount,
                progressHandler: progressHandler
            )
        }

        for folderAction in folderActions(in: workspace) {
            append(fileFolderOpener.openFolder(folderAction), to: &result)
            completedUnits += 1
            publishAndDelayIfNeeded(
                workspace: workspace,
                stage: .openingFolders,
                message: "Opening folders...",
                result: result,
                completedUnits: completedUnits,
                totalUnits: totalUnitCount,
                totalActionCount: totalActionCount,
                progressHandler: progressHandler
            )
        }

        for urlAction in urlActions(in: workspace) {
            append(urlOpener.open(urlAction), to: &result)
            completedUnits += 1
            publishAndDelayIfNeeded(
                workspace: workspace,
                stage: .openingURLs,
                message: "Opening URLs...",
                result: result,
                completedUnits: completedUnits,
                totalUnits: totalUnitCount,
                totalActionCount: totalActionCount,
                progressHandler: progressHandler
            )
        }

        for codeProjectAction in codeProjectActions(in: workspace) {
            append(vsCodeLauncher.open(codeProjectAction), to: &result)
            completedUnits += 1
            publishAndDelayIfNeeded(
                workspace: workspace,
                stage: .openingCodeProjects,
                message: "Opening VS Code projects...",
                result: result,
                completedUnits: completedUnits,
                totalUnits: totalUnitCount,
                totalActionCount: totalActionCount,
                progressHandler: progressHandler
            )
        }

        for terminalAction in terminalActions(in: workspace) {
            append(terminalManager.run(terminalAction), to: &result)
            completedUnits += 1
            publishAndDelayIfNeeded(
                workspace: workspace,
                stage: .runningTerminalCommands,
                message: "Running terminal commands...",
                result: result,
                completedUnits: completedUnits,
                totalUnits: totalUnitCount,
                totalActionCount: totalActionCount,
                progressHandler: progressHandler
            )
        }

        if totalActionCount == 0 && workspace.windowLayouts.isEmpty {
            let skippedResult = ActionLaunchResult(
                actionType: "workspace",
                title: "Workspace Launch",
                status: .skipped,
                message: "No app, file, folder, URL, VS Code project, or terminal command actions are saved in this workspace."
            )
            append(skippedResult, to: &result)
        }

        if !workspace.windowLayouts.isEmpty {
            publishProgress(
                workspace: workspace,
                stage: .waitingForWindows,
                message: "Waiting for launched windows...",
                result: result,
                completedUnits: completedUnits,
                totalUnits: totalUnitCount,
                progressHandler: progressHandler
            )
            sleep(configuration.layoutDelay)

            for layoutResult in windowLayoutRestorer.restore(workspace.windowLayouts) {
                appendLayout(layoutResult, to: &result)
                completedUnits += 1
                publishProgress(
                    workspace: workspace,
                    stage: .applyingWindowLayout,
                    message: "Applying window layout...",
                    result: result,
                    completedUnits: completedUnits,
                    totalUnits: totalUnitCount,
                    progressHandler: progressHandler
                )
            }
        }

        result.finishedAt = Date()
        publishProgress(
            workspace: workspace,
            stage: .finished,
            message: result.hasFailures ? "Workspace launched with issues." : "Workspace launch finished.",
            result: result,
            completedUnits: max(completedUnits, result.allResults.isEmpty ? 0 : completedUnits),
            totalUnits: totalUnitCount,
            progressHandler: progressHandler
        )
        return result
    }

    func launchWorkspaceActionsAsync(
        in workspace: Workspace,
        progressHandler: ProgressHandler? = nil,
        completion: @escaping CompletionHandler
    ) {
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            let result = launchWorkspaceActions(in: workspace) { snapshot in
                DispatchQueue.main.async {
                    progressHandler?(snapshot)
                }
            }

            DispatchQueue.main.async {
                completion(result)
            }
        }
    }

    func launchAppActions(in workspace: Workspace) -> WorkspaceLaunchResult {
        launchWorkspaceActions(in: workspace)
    }

    private func append(_ actionResult: ActionLaunchResult, to result: inout WorkspaceLaunchResult) {
        result.actionResults.append(actionResult)
        errorLogger.logActionResult(actionResult)
    }

    private func appendLayout(_ actionResult: ActionLaunchResult, to result: inout WorkspaceLaunchResult) {
        result.layoutResults.append(actionResult)
        errorLogger.logActionResult(actionResult)
    }

    private func publishProgress(
        workspace: Workspace,
        stage: WorkspaceLaunchProgressStage,
        message: String,
        result: WorkspaceLaunchResult,
        completedUnits: Int,
        totalUnits: Int,
        progressHandler: ProgressHandler?
    ) {
        progressHandler?(WorkspaceLaunchProgressSnapshot(
            workspaceID: workspace.id,
            workspaceName: workspace.name,
            stage: stage,
            message: message,
            completedUnits: completedUnits,
            totalUnits: totalUnits,
            actionResults: result.actionResults,
            layoutResults: result.layoutResults
        ))
    }

    private func publishAndDelayIfNeeded(
        workspace: Workspace,
        stage: WorkspaceLaunchProgressStage,
        message: String,
        result: WorkspaceLaunchResult,
        completedUnits: Int,
        totalUnits: Int,
        totalActionCount: Int,
        progressHandler: ProgressHandler?
    ) {
        publishProgress(
            workspace: workspace,
            stage: stage,
            message: message,
            result: result,
            completedUnits: completedUnits,
            totalUnits: totalUnits,
            progressHandler: progressHandler
        )

        if completedUnits < totalActionCount {
            sleep(configuration.actionDelay)
        }
    }

    private func workspaceValidationFailure(workspace: Workspace, message: String) -> ActionLaunchResult {
        ActionLaunchResult(
            actionType: "workspace",
            title: "Workspace Validation",
            status: .failed,
            message: message,
            errorCode: "workspace_validation_failed"
        )
    }

    private func launchableActionCount(in workspace: Workspace) -> Int {
        appActions(in: workspace).count
            + fileActions(in: workspace).count
            + folderActions(in: workspace).count
            + urlActions(in: workspace).count
            + codeProjectActions(in: workspace).count
            + terminalActions(in: workspace).count
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

    private func terminalActions(in workspace: Workspace) -> [TerminalCommandAction] {
        workspace.actions.compactMap { action in
            if case .terminalCommand(let payload) = action {
                return payload
            }

            return nil
        }
    }

    private func codeProjectActions(in workspace: Workspace) -> [OpenVSCodeProjectAction] {
        workspace.actions.compactMap { action in
            if case .openVSCodeProject(let payload) = action {
                return payload
            }

            return nil
        }
    }
}

typealias WorkspaceAppRunner = WorkspaceRunner
