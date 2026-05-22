import AppKit
import Foundation

final class FileFolderOpener {
    private let fileManager: FileManager
    private let openResource: (URL) -> Bool

    init(
        fileManager: FileManager = .default,
        openResource: @escaping (URL) -> Bool = { url in
            NSWorkspace.shared.open(url)
        }
    ) {
        self.fileManager = fileManager
        self.openResource = openResource
    }

    func openFile(_ action: OpenFileAction) -> ActionLaunchResult {
        openResourceAction(
            id: action.id,
            actionType: WorkspaceActionType.openFile.rawValue,
            title: action.name,
            path: action.path,
            bookmarkData: action.securityScopedBookmarkData,
            expectedDirectory: false
        )
    }

    func openFolder(_ action: OpenFolderAction) -> ActionLaunchResult {
        openResourceAction(
            id: action.id,
            actionType: WorkspaceActionType.openFolder.rawValue,
            title: action.name,
            path: action.path,
            bookmarkData: action.securityScopedBookmarkData,
            expectedDirectory: true
        )
    }

    private func openResourceAction(
        id: UUID,
        actionType: String,
        title: String,
        path: String,
        bookmarkData: Data?,
        expectedDirectory: Bool
    ) -> ActionLaunchResult {
        let displayTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? URL(fileURLWithPath: path).lastPathComponent
            : title

        let resolvedURL = resolveURL(path: path, bookmarkData: bookmarkData)
        let url = resolvedURL.url
        var isDirectory: ObjCBool = false

        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return ActionLaunchResult(
                actionID: id,
                actionType: actionType,
                title: displayTitle,
                status: .failed,
                message: "\(expectedDirectory ? "Folder" : "File") could not be found at \(path).",
                errorCode: expectedDirectory ? "missing_folder" : "missing_file"
            )
        }

        guard isDirectory.boolValue == expectedDirectory else {
            return ActionLaunchResult(
                actionID: id,
                actionType: actionType,
                title: displayTitle,
                status: .failed,
                message: expectedDirectory ? "Selected path is not a folder." : "Selected path is a folder, not a file.",
                errorCode: expectedDirectory ? "invalid_folder_path" : "invalid_file_path"
            )
        }

        let didStartSecurityScope = url.startAccessingSecurityScopedResource()
        defer {
            if didStartSecurityScope {
                url.stopAccessingSecurityScopedResource()
            }
        }

        guard openResource(url) else {
            return ActionLaunchResult(
                actionID: id,
                actionType: actionType,
                title: displayTitle,
                status: .failed,
                message: "macOS could not open \(displayTitle).",
                errorCode: expectedDirectory ? "folder_open_failed" : "file_open_failed"
            )
        }

        return ActionLaunchResult(
            actionID: id,
            actionType: actionType,
            title: displayTitle,
            status: .succeeded,
            message: "Opened \(displayTitle)."
        )
    }

    private func resolveURL(path: String, bookmarkData: Data?) -> (url: URL, isStale: Bool) {
        guard let bookmarkData else {
            return (URL(fileURLWithPath: path), false)
        }

        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            return (url, isStale)
        } catch {
            return (URL(fileURLWithPath: path), false)
        }
    }
}
