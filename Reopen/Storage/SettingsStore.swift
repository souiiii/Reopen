import Foundation

struct SettingsLoadResult: Equatable {
    var settings: AppSettings
    var storageError: StorageError?
}

final class SettingsStore {
    private let storageManager: StorageManager
    private let backupManager: JSONBackupManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        storageManager: StorageManager,
        backupManager: JSONBackupManager
    ) {
        self.storageManager = storageManager
        self.backupManager = backupManager

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder

        self.decoder = JSONDecoder()
    }

    func loadSettings() -> SettingsLoadResult {
        do {
            try storageManager.ensureApplicationSupportDirectory()

            let fileURL = storageManager.settingsFileURL
            guard storageManager.fileManager.fileExists(atPath: fileURL.path) else {
                return SettingsLoadResult(settings: AppSettings(), storageError: nil)
            }

            let data: Data
            do {
                data = try Data(contentsOf: fileURL)
            } catch {
                return SettingsLoadResult(
                    settings: AppSettings(),
                    storageError: .readFailed(path: fileURL.path, reason: error.localizedDescription)
                )
            }

            do {
                return SettingsLoadResult(
                    settings: try decoder.decode(AppSettings.self, from: data),
                    storageError: nil
                )
            } catch {
                return SettingsLoadResult(
                    settings: AppSettings(),
                    storageError: .corruptedSettingsData(path: fileURL.path, reason: error.localizedDescription)
                )
            }
        } catch let storageError as StorageError {
            return SettingsLoadResult(settings: AppSettings(), storageError: storageError)
        } catch {
            return SettingsLoadResult(
                settings: AppSettings(),
                storageError: .readFailed(path: storageManager.settingsFileURL.path, reason: error.localizedDescription)
            )
        }
    }

    func saveSettings(_ settings: AppSettings) throws {
        try storageManager.ensureApplicationSupportDirectory()

        let data: Data
        do {
            data = try encoder.encode(settings)
            _ = try decoder.decode(AppSettings.self, from: data)
        } catch {
            throw StorageError.encodedDataValidationFailed(reason: error.localizedDescription)
        }

        let fileURL = storageManager.settingsFileURL
        try backupManager.createBackupIfNeeded(for: fileURL)

        do {
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            throw StorageError.writeFailed(path: fileURL.path, reason: error.localizedDescription)
        }
    }

    func resetSettings() throws {
        try saveSettings(AppSettings())
    }
}
