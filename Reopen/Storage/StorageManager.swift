import Foundation

final class StorageManager {
    let fileManager: FileManager
    let applicationSupportDirectory: URL

    var workspacesFileURL: URL {
        applicationSupportDirectory.appendingPathComponent("workspaces.json", isDirectory: false)
    }

    var settingsFileURL: URL {
        applicationSupportDirectory.appendingPathComponent("settings.json", isDirectory: false)
    }

    var backupsDirectoryURL: URL {
        applicationSupportDirectory.appendingPathComponent("backups", isDirectory: true)
    }

    init(fileManager: FileManager = .default, applicationSupportDirectory: URL? = nil) {
        self.fileManager = fileManager
        self.applicationSupportDirectory = applicationSupportDirectory ?? Self.defaultApplicationSupportDirectory(fileManager: fileManager)
    }

    func ensureApplicationSupportDirectory() throws {
        do {
            try fileManager.createDirectory(
                at: applicationSupportDirectory,
                withIntermediateDirectories: true
            )
        } catch {
            throw StorageError.directoryCreationFailed(
                path: applicationSupportDirectory.path,
                reason: error.localizedDescription
            )
        }
    }

    func ensureBackupsDirectory() throws {
        do {
            try fileManager.createDirectory(
                at: backupsDirectoryURL,
                withIntermediateDirectories: true
            )
        } catch {
            throw StorageError.directoryCreationFailed(
                path: backupsDirectoryURL.path,
                reason: error.localizedDescription
            )
        }
    }

    private static func defaultApplicationSupportDirectory(fileManager: FileManager) -> URL {
        guard let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return URL(fileURLWithPath: NSHomeDirectory())
                .appendingPathComponent("Library", isDirectory: true)
                .appendingPathComponent("Application Support", isDirectory: true)
                .appendingPathComponent("Reopen", isDirectory: true)
        }

        return baseURL.appendingPathComponent("Reopen", isDirectory: true)
    }
}
