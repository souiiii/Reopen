import Foundation

final class JSONBackupManager {
    private let storageManager: StorageManager

    init(storageManager: StorageManager) {
        self.storageManager = storageManager
    }

    @discardableResult
    func createBackupIfNeeded(for fileURL: URL) throws -> URL? {
        guard storageManager.fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        try storageManager.ensureBackupsDirectory()

        let backupURL = uniqueBackupURL(for: fileURL)

        do {
            try storageManager.fileManager.copyItem(at: fileURL, to: backupURL)
            return backupURL
        } catch {
            throw StorageError.backupFailed(
                path: fileURL.path,
                reason: error.localizedDescription
            )
        }
    }

    private func uniqueBackupURL(for fileURL: URL) -> URL {
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let baseName = fileURL.deletingPathExtension().lastPathComponent
        let fileExtension = fileURL.pathExtension
        let fileName = "\(baseName)-\(timestamp).\(fileExtension)"
        var candidate = storageManager.backupsDirectoryURL.appendingPathComponent(fileName, isDirectory: false)

        if storageManager.fileManager.fileExists(atPath: candidate.path) {
            candidate = storageManager.backupsDirectoryURL.appendingPathComponent(
                "\(baseName)-\(timestamp)-\(UUID().uuidString).\(fileExtension)",
                isDirectory: false
            )
        }

        return candidate
    }
}
