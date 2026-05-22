import Foundation

enum VSCodeProjectCheckFailure: Error, CustomStringConvertible {
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
        throw VSCodeProjectCheckFailure.message(message)
    }
}

@main
enum VSCodeProjectChecks {
    static func main() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ReopenVSCodeProjectChecks-\(UUID().uuidString)", isDirectory: true)
        let projectURL = temporaryDirectory.appendingPathComponent("My App", isDirectory: true)
        let cliURL = temporaryDirectory.appendingPathComponent("code", isDirectory: false)
        let appURL = temporaryDirectory.appendingPathComponent("Visual Studio Code.app", isDirectory: true)

        defer {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }

        try FileManager.default.createDirectory(at: projectURL, withIntermediateDirectories: true)
        try makeExecutableFile(at: cliURL)
        try FileManager.default.createDirectory(at: appURL, withIntermediateDirectories: true)

        try projectDraftSavesAndPreservesEditor(projectURL: projectURL)
        try codeCommandIsPreferred(projectURL: projectURL, cliURL: cliURL, appURL: appURL)
        try fallsBackToVSCodeAppWhenCodeCommandFails(projectURL: projectURL, cliURL: cliURL, appURL: appURL)
        try missingVSCodeFailsGracefully(projectURL: projectURL)
        try missingProjectFolderFailsClearly(temporaryDirectory: temporaryDirectory, cliURL: cliURL)
        try invalidProjectPathFailsClearly(temporaryDirectory: temporaryDirectory, cliURL: cliURL)
        try workspaceRunnerOpensCodeProjectsBeforeTerminalCommands(projectURL: projectURL, cliURL: cliURL)

        print("VS Code project checks passed.")
    }

    private static func projectDraftSavesAndPreservesEditor(projectURL: URL) throws {
        let draft = WorkspaceCreationDraft(
            name: "Coding",
            actions: [
                .vsCodeProject(path: projectURL.path)
            ]
        )
        let workspace = try draft.makeWorkspace()

        guard case .openVSCodeProject(let action) = workspace.actions.first else {
            throw VSCodeProjectCheckFailure.message("Expected VS Code project action.")
        }

        let editDraft = WorkspaceActionDraft(action: .openVSCodeProject(action))

        try check(action.projectPath == projectURL.path, "VS Code project path should be saved.")
        try check(action.editor == "vscode", "VS Code project should default to vscode editor.")
        try check(editDraft.editor == "vscode", "Editing a VS Code action should preserve editor metadata.")
    }

    private static func codeCommandIsPreferred(projectURL: URL, cliURL: URL, appURL: URL) throws {
        var invocations: [(String, [String])] = []
        let launcher = VSCodeLauncher(
            cliCandidatePaths: [cliURL.path],
            appCandidatePaths: [appURL.path],
            runProcess: { executable, arguments in
                invocations.append((executable, arguments))
                return .success
            }
        )

        let result = launcher.open(OpenVSCodeProjectAction(projectPath: projectURL.path))

        try check(result.status == .succeeded, "VS Code project should open with available code command.")
        try check(invocations.count == 1, "Code command should be used without app fallback when it succeeds.")
        try check(invocations[0].0 == cliURL.path, "VSCodeLauncher should prefer the detected code CLI.")
        try check(invocations[0].1 == [projectURL.path], "Code command should receive the project path.")
    }

    private static func fallsBackToVSCodeAppWhenCodeCommandFails(projectURL: URL, cliURL: URL, appURL: URL) throws {
        var invocations: [(String, [String])] = []
        let launcher = VSCodeLauncher(
            cliCandidatePaths: [cliURL.path],
            appCandidatePaths: [appURL.path],
            runProcess: { executable, arguments in
                invocations.append((executable, arguments))
                return executable == cliURL.path ? .failure(message: "code failed") : .success
            }
        )

        let result = launcher.open(OpenVSCodeProjectAction(projectPath: projectURL.path))

        try check(result.status == .succeeded, "VS Code app fallback should succeed when code command fails.")
        try check(invocations.count == 2, "Launcher should try code first, then app fallback.")
        try check(invocations[0].0 == cliURL.path, "First attempt should use code CLI.")
        try check(invocations[1].0 == "/usr/bin/open", "Fallback should use macOS open.")
        try check(invocations[1].1 == ["-a", appURL.path, projectURL.path], "Fallback should open the project with VS Code app.")
    }

    private static func missingVSCodeFailsGracefully(projectURL: URL) throws {
        var invocations: [(String, [String])] = []
        let launcher = VSCodeLauncher(
            cliCandidatePaths: [],
            appCandidatePaths: [],
            runProcess: { executable, arguments in
                invocations.append((executable, arguments))
                return .success
            }
        )

        let result = launcher.open(OpenVSCodeProjectAction(projectPath: projectURL.path))

        try check(result.status == .failed, "Missing VS Code should fail gracefully.")
        try check(result.errorCode == "missing_vscode", "Missing VS Code should use missing_vscode.")
        try check(invocations.isEmpty, "Missing VS Code should not attempt to run a process.")
    }

    private static func missingProjectFolderFailsClearly(temporaryDirectory: URL, cliURL: URL) throws {
        let launcher = VSCodeLauncher(
            cliCandidatePaths: [cliURL.path],
            appCandidatePaths: [],
            runProcess: { _, _ in .success }
        )

        let result = launcher.open(OpenVSCodeProjectAction(
            projectPath: temporaryDirectory.appendingPathComponent("Missing").path
        ))

        try check(result.status == .failed, "Missing project folder should fail.")
        try check(result.errorCode == "missing_code_project", "Missing project folder should use missing_code_project.")
    }

    private static func invalidProjectPathFailsClearly(temporaryDirectory: URL, cliURL: URL) throws {
        let fileURL = temporaryDirectory.appendingPathComponent("not-a-folder.txt", isDirectory: false)
        try Data("not a folder".utf8).write(to: fileURL)

        let launcher = VSCodeLauncher(
            cliCandidatePaths: [cliURL.path],
            appCandidatePaths: [],
            runProcess: { _, _ in .success }
        )

        let result = launcher.open(OpenVSCodeProjectAction(projectPath: fileURL.path))

        try check(result.status == .failed, "File project path should fail.")
        try check(result.errorCode == "invalid_code_project_path", "File project path should use invalid_code_project_path.")
    }

    private static func workspaceRunnerOpensCodeProjectsBeforeTerminalCommands(projectURL: URL, cliURL: URL) throws {
        var sequence: [String] = []
        let runner = WorkspaceAppRunner(
            appLauncher: AppLauncher(openApplication: { _ in true }),
            fileFolderOpener: FileFolderOpener(openResource: { _ in true }),
            urlOpener: URLOpener(openURL: { _ in
                sequence.append("url")
                return true
            }),
            vsCodeLauncher: VSCodeLauncher(
                cliCandidatePaths: [cliURL.path],
                appCandidatePaths: [],
                runProcess: { _, _ in
                    sequence.append("code")
                    return .success
                }
            ),
            terminalManager: TerminalManager(
                executor: AppleScriptTerminalExecutor(executeAppleScript: { _ in
                    sequence.append("terminal")
                    return .success
                }),
                confirmationProvider: { _, _ in true }
            ),
            errorLogger: ErrorLogger()
        )
        let workspace = Workspace(
            name: "Coding",
            actions: [
                .terminalCommand(TerminalCommandAction(
                    name: "Dev",
                    command: "npm run dev",
                    workingDirectory: projectURL.path,
                    requiresConfirmation: false
                )),
                .openURL(OpenURLAction(url: "https://example.com")),
                .openVSCodeProject(OpenVSCodeProjectAction(projectPath: projectURL.path))
            ]
        )

        let result = runner.launchWorkspaceActions(in: workspace)

        try check(result.actionResults.count == 3, "Runner should report URL, code project, and terminal actions.")
        try check(sequence == ["url", "code", "terminal"], "Runner should open code projects after URLs and before terminal commands.")
    }

    private static func makeExecutableFile(at url: URL) throws {
        try Data("#!/bin/sh\nexit 0\n".utf8).write(to: url)
        try FileManager.default.setAttributes(
            [.posixPermissions: NSNumber(value: Int16(0o755))],
            ofItemAtPath: url.path
        )
    }
}
