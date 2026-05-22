import Foundation

struct ProcessLaunchResult: Equatable {
    var succeeded: Bool
    var exitCode: Int32
    var errorMessage: String?

    static let success = ProcessLaunchResult(succeeded: true, exitCode: 0, errorMessage: nil)

    static func failure(exitCode: Int32 = 1, message: String? = nil) -> ProcessLaunchResult {
        ProcessLaunchResult(succeeded: false, exitCode: exitCode, errorMessage: message)
    }
}

final class VSCodeLauncher {
    typealias RunProcess = (String, [String]) -> ProcessLaunchResult

    private let fileManager: FileManager
    private let cliCandidatePaths: [String]
    private let appCandidatePaths: [String]
    private let runProcess: RunProcess

    init(
        fileManager: FileManager = .default,
        cliCandidatePaths: [String] = VSCodeLauncher.defaultCLICandidatePaths(),
        appCandidatePaths: [String] = VSCodeLauncher.defaultAppCandidatePaths(),
        runProcess: @escaping RunProcess = VSCodeLauncher.runProcess
    ) {
        self.fileManager = fileManager
        self.cliCandidatePaths = cliCandidatePaths
        self.appCandidatePaths = appCandidatePaths
        self.runProcess = runProcess
    }

    func open(_ action: OpenVSCodeProjectAction) -> ActionLaunchResult {
        let projectPath = action.projectPath.trimmingCharacters(in: .whitespacesAndNewlines)
        let projectURL = URL(fileURLWithPath: projectPath)
        let title = projectURL.lastPathComponent.isEmpty ? "VS Code Project" : projectURL.lastPathComponent

        var isDirectory = ObjCBool(false)
        guard fileManager.fileExists(atPath: projectPath, isDirectory: &isDirectory) else {
            return failure(
                action: action,
                title: title,
                message: "Project folder could not be found at \(action.projectPath).",
                errorCode: "missing_code_project"
            )
        }

        guard isDirectory.boolValue else {
            return failure(
                action: action,
                title: title,
                message: "Selected project path is not a folder.",
                errorCode: "invalid_code_project_path"
            )
        }

        let cliPath = firstExecutablePath(in: cliCandidatePaths)
        let appPath = firstApplicationPath(in: appCandidatePaths)

        if let cliPath {
            let cliResult = runProcess(cliPath, [projectPath])
            if cliResult.succeeded {
                return ActionLaunchResult(
                    actionID: action.id,
                    actionType: WorkspaceActionType.openVSCodeProject.rawValue,
                    title: title,
                    status: .succeeded,
                    message: "Opened \(title) in VS Code with the code command."
                )
            }

            if let appPath {
                return openWithApp(
                    action: action,
                    title: title,
                    appPath: appPath,
                    projectPath: projectPath,
                    fallbackMessage: "The code command failed, so Reopen opened \(title) with the VS Code app."
                )
            }

            return failure(
                action: action,
                title: title,
                message: cliResult.errorMessage ?? "The code command could not open \(title).",
                errorCode: "code_command_failed"
            )
        }

        guard let appPath else {
            return failure(
                action: action,
                title: title,
                message: "Visual Studio Code could not be found. Install VS Code or enable the code command.",
                errorCode: "missing_vscode"
            )
        }

        return openWithApp(
            action: action,
            title: title,
            appPath: appPath,
            projectPath: projectPath,
            fallbackMessage: nil
        )
    }

    private func openWithApp(
        action: OpenVSCodeProjectAction,
        title: String,
        appPath: String,
        projectPath: String,
        fallbackMessage: String?
    ) -> ActionLaunchResult {
        let result = runProcess("/usr/bin/open", ["-a", appPath, projectPath])
        guard result.succeeded else {
            return failure(
                action: action,
                title: title,
                message: result.errorMessage ?? "VS Code could not open \(title).",
                errorCode: "vscode_open_failed"
            )
        }

        return ActionLaunchResult(
            actionID: action.id,
            actionType: WorkspaceActionType.openVSCodeProject.rawValue,
            title: title,
            status: .succeeded,
            message: fallbackMessage ?? "Opened \(title) in VS Code."
        )
    }

    private func firstExecutablePath(in paths: [String]) -> String? {
        paths.first { path in
            fileManager.fileExists(atPath: path) && fileManager.isExecutableFile(atPath: path)
        }
    }

    private func firstApplicationPath(in paths: [String]) -> String? {
        paths.first { path in
            var isDirectory = ObjCBool(false)
            return fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
                && isDirectory.boolValue
                && URL(fileURLWithPath: path).pathExtension == "app"
        }
    }

    private func failure(
        action: OpenVSCodeProjectAction,
        title: String,
        message: String,
        errorCode: String
    ) -> ActionLaunchResult {
        ActionLaunchResult(
            actionID: action.id,
            actionType: WorkspaceActionType.openVSCodeProject.rawValue,
            title: title,
            status: .failed,
            message: message,
            errorCode: errorCode
        )
    }

    private static func defaultCLICandidatePaths() -> [String] {
        let home = NSHomeDirectory()
        return [
            "/usr/local/bin/code",
            "/opt/homebrew/bin/code",
            "/usr/bin/code",
            "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code",
            "\(home)/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
        ]
    }

    private static func defaultAppCandidatePaths() -> [String] {
        let home = NSHomeDirectory()
        return [
            "/Applications/Visual Studio Code.app",
            "\(home)/Applications/Visual Studio Code.app",
            "/Applications/Visual Studio Code - Insiders.app",
            "\(home)/Applications/Visual Studio Code - Insiders.app"
        ]
    }

    private static func runProcess(executablePath: String, arguments: [String]) -> ProcessLaunchResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return .failure(message: error.localizedDescription)
        }

        guard process.terminationStatus == 0 else {
            return .failure(exitCode: process.terminationStatus)
        }

        return .success
    }
}
