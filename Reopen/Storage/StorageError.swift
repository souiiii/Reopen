import Foundation

enum StorageError: Error, Equatable {
    case applicationSupportDirectoryUnavailable
    case directoryCreationFailed(path: String, reason: String)
    case readFailed(path: String, reason: String)
    case writeFailed(path: String, reason: String)
    case backupFailed(path: String, reason: String)
    case corruptedWorkspaceData(path: String, reason: String)
    case corruptedSettingsData(path: String, reason: String)
    case migrationFailed(reason: String)
    case encodedDataValidationFailed(reason: String)

    var userFacingMessage: String {
        switch self {
        case .applicationSupportDirectoryUnavailable:
            return "Storage error: Application Support is unavailable."
        case .directoryCreationFailed:
            return "Storage error: Reopen could not create its data folder."
        case .readFailed:
            return "Storage error: Reopen could not read saved workspaces."
        case .writeFailed:
            return "Storage error: Reopen could not save workspaces."
        case .backupFailed:
            return "Storage error: Reopen could not back up existing workspace data."
        case .corruptedWorkspaceData:
            return "Storage error: Saved workspace data is corrupted."
        case .corruptedSettingsData:
            return "Storage error: Saved settings are corrupted."
        case .migrationFailed:
            return "Storage error: Saved workspace data could not be migrated."
        case .encodedDataValidationFailed:
            return "Storage error: Reopen could not validate workspace data before saving."
        }
    }
}
