import Foundation

enum FileFolderOpeningCheckFailure: Error, CustomStringConvertible {
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
        throw FileFolderOpeningCheckFailure.message(message)
    }
}

@main
enum FileFolderOpeningChecks {
    static func main() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ReopenFileFolderOpeningChecks-\(UUID().uuidString)", isDirectory: true)

        defer {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }

        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)

        let fileURL = temporaryDirectory.appendingPathComponent("brief.txt", isDirectory: false)
        let folderURL = temporaryDirectory.appendingPathComponent("Project", isDirectory: true)
        try Data("brief".utf8).write(to: fileURL)
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)

        try fileOpenUsesDefaultOpen(fileURL: fileURL)
        try folderOpenUsesDefaultOpen(folderURL: folderURL)
        try missingFileFailsGracefully(temporaryDirectory: temporaryDirectory)
        try missingFolderFailsGracefully(temporaryDirectory: temporaryDirectory)
        try invalidFileAndFolderTypesFail(fileURL: fileURL, folderURL: folderURL)
        try workspaceRunnerContinuesAfterMissingResource(fileURL: fileURL, folderURL: folderURL, temporaryDirectory: temporaryDirectory)

        print("File and folder opening checks passed.")
    }

    private static func fileOpenUsesDefaultOpen(fileURL: URL) throws {
        var openedURLs: [URL] = []
        let opener = FileFolderOpener(openResource: { url in
            openedURLs.append(url)
            return true
        })

        let result = opener.openFile(OpenFileAction(name: "Brief", path: fileURL.path))

        try check(result.status == .succeeded, "Existing file should open successfully.")
        try check(openedURLs == [fileURL], "File opener should call the injected openResource closure.")
    }

    private static func folderOpenUsesDefaultOpen(folderURL: URL) throws {
        var openedURLs: [URL] = []
        let opener = FileFolderOpener(openResource: { url in
            openedURLs.append(url)
            return true
        })

        let result = opener.openFolder(OpenFolderAction(name: "Project", path: folderURL.path))

        try check(result.status == .succeeded, "Existing folder should open successfully.")
        try check(openedURLs == [folderURL], "Folder opener should call the injected openResource closure.")
    }

    private static func missingFileFailsGracefully(temporaryDirectory: URL) throws {
        let opener = FileFolderOpener(openResource: { _ in true })
        let result = opener.openFile(OpenFileAction(
            name: "Missing File",
            path: temporaryDirectory.appendingPathComponent("missing.txt").path
        ))

        try check(result.status == .failed, "Missing file should fail gracefully.")
        try check(result.errorCode == "missing_file", "Missing file should use missing_file error code.")
    }

    private static func missingFolderFailsGracefully(temporaryDirectory: URL) throws {
        let opener = FileFolderOpener(openResource: { _ in true })
        let result = opener.openFolder(OpenFolderAction(
            name: "Missing Folder",
            path: temporaryDirectory.appendingPathComponent("MissingFolder").path
        ))

        try check(result.status == .failed, "Missing folder should fail gracefully.")
        try check(result.errorCode == "missing_folder", "Missing folder should use missing_folder error code.")
    }

    private static func invalidFileAndFolderTypesFail(fileURL: URL, folderURL: URL) throws {
        let opener = FileFolderOpener(openResource: { _ in true })
        let folderAsFile = opener.openFile(OpenFileAction(name: "Folder As File", path: folderURL.path))
        let fileAsFolder = opener.openFolder(OpenFolderAction(name: "File As Folder", path: fileURL.path))

        try check(folderAsFile.status == .failed, "Opening a folder as a file should fail.")
        try check(folderAsFile.errorCode == "invalid_file_path", "Folder-as-file should use invalid_file_path.")
        try check(fileAsFolder.status == .failed, "Opening a file as a folder should fail.")
        try check(fileAsFolder.errorCode == "invalid_folder_path", "File-as-folder should use invalid_folder_path.")
    }

    private static func workspaceRunnerContinuesAfterMissingResource(
        fileURL: URL,
        folderURL: URL,
        temporaryDirectory: URL
    ) throws {
        var openedURLs: [URL] = []
        let runner = WorkspaceAppRunner(
            appLauncher: AppLauncher(openApplication: { _ in true }),
            fileFolderOpener: FileFolderOpener(openResource: { url in
                openedURLs.append(url)
                return true
            }),
            urlOpener: URLOpener(openURL: { _ in true }),
            vsCodeLauncher: VSCodeLauncher(runProcess: { _, _ in .success }),
            terminalManager: TerminalManager(
                executor: AppleScriptTerminalExecutor(executeAppleScript: { _ in .success }),
                confirmationProvider: { _, _ in true }
            ),
            errorLogger: ErrorLogger()
        )
        let workspace = Workspace(
            name: "Files",
            actions: [
                .openFile(OpenFileAction(
                    name: "Missing",
                    path: temporaryDirectory.appendingPathComponent("missing.txt").path
                )),
                .openFile(OpenFileAction(name: "Brief", path: fileURL.path)),
                .openFolder(OpenFolderAction(name: "Project", path: folderURL.path))
            ]
        )

        let result = runner.launchAppActions(in: workspace)

        try check(result.actionResults.count == 3, "Runner should report every file/folder action.")
        try check(result.actionResults[0].status == .failed, "Missing file should fail.")
        try check(result.actionResults[1].status == .succeeded, "Runner should continue after missing file.")
        try check(result.actionResults[2].status == .succeeded, "Runner should continue to folder action.")
        try check(openedURLs == [fileURL, folderURL], "Only existing file/folder resources should be opened.")
    }
}
