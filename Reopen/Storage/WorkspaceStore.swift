import Foundation

struct WorkspaceLoadResult: Equatable {
    var workspaces: [Workspace]
    var storageError: StorageError?
}

final class WorkspaceStore {
    private let storageManager: StorageManager
    private let migrationManager: MigrationManager
    private let backupManager: JSONBackupManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        storageManager: StorageManager,
        migrationManager: MigrationManager,
        backupManager: JSONBackupManager
    ) {
        self.storageManager = storageManager
        self.migrationManager = migrationManager
        self.backupManager = backupManager

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder

        self.decoder = JSONDecoder()
    }

    func loadWorkspaces() -> WorkspaceLoadResult {
        do {
            try storageManager.ensureApplicationSupportDirectory()

            let fileURL = storageManager.workspacesFileURL
            guard storageManager.fileManager.fileExists(atPath: fileURL.path) else {
                return WorkspaceLoadResult(workspaces: [], storageError: nil)
            }

            let data: Data
            do {
                data = try Data(contentsOf: fileURL)
            } catch {
                return WorkspaceLoadResult(
                    workspaces: [],
                    storageError: .readFailed(path: fileURL.path, reason: error.localizedDescription)
                )
            }

            do {
                let workspaces = try migrationManager.decodeWorkspaces(from: data, using: decoder)
                return WorkspaceLoadResult(workspaces: workspaces, storageError: nil)
            } catch let storageError as StorageError {
                return WorkspaceLoadResult(
                    workspaces: [],
                    storageError: normalizeCorruptionPath(storageError, path: fileURL.path)
                )
            } catch {
                return WorkspaceLoadResult(
                    workspaces: [],
                    storageError: .corruptedWorkspaceData(path: fileURL.path, reason: error.localizedDescription)
                )
            }
        } catch let storageError as StorageError {
            return WorkspaceLoadResult(workspaces: [], storageError: storageError)
        } catch {
            return WorkspaceLoadResult(
                workspaces: [],
                storageError: .readFailed(path: storageManager.workspacesFileURL.path, reason: error.localizedDescription)
            )
        }
    }

    func saveWorkspaces(_ workspaces: [Workspace]) throws {
        try storageManager.ensureApplicationSupportDirectory()

        let data: Data
        do {
            data = try migrationManager.encodeWorkspaces(workspaces, using: encoder)
            _ = try migrationManager.decodeWorkspaces(from: data, using: decoder)
        } catch let storageError as StorageError {
            throw storageError
        } catch {
            throw StorageError.encodedDataValidationFailed(reason: error.localizedDescription)
        }

        let fileURL = storageManager.workspacesFileURL
        try backupManager.createBackupIfNeeded(for: fileURL)

        do {
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            throw StorageError.writeFailed(path: fileURL.path, reason: error.localizedDescription)
        }
    }

    private func normalizeCorruptionPath(_ error: StorageError, path: String) -> StorageError {
        switch error {
        case .corruptedWorkspaceData(_, let reason):
            return .corruptedWorkspaceData(path: path, reason: reason)
        default:
            return error
        }
    }
}
