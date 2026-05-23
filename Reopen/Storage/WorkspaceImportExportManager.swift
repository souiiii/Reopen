import Foundation

struct WorkspaceImportResult: Equatable {
    var workspaces: [Workspace]
    var importedCount: Int
}

enum WorkspaceImportExportError: Error, Equatable {
    case readFailed(path: String, reason: String)
    case writeFailed(path: String, reason: String)
    case invalidWorkspaceData(String)

    var userFacingMessage: String {
        switch self {
        case .readFailed:
            return "Import failed because Reopen could not read the selected file."
        case .writeFailed:
            return "Export failed because Reopen could not write the selected file."
        case .invalidWorkspaceData(let reason):
            return "Import failed: \(reason)"
        }
    }
}

final class WorkspaceImportExportManager {
    private let migrationManager: MigrationManager
    private let validator: WorkspaceValidator
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        migrationManager: MigrationManager = MigrationManager(),
        validator: WorkspaceValidator = WorkspaceValidator()
    ) {
        self.migrationManager = migrationManager
        self.validator = validator

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder

        self.decoder = JSONDecoder()
    }

    func exportWorkspaces(_ workspaces: [Workspace], to url: URL) throws {
        let data: Data
        do {
            try validator.validateWorkspaceCollection(workspaces)
            data = try migrationManager.encodeWorkspaces(workspaces, using: encoder)
        } catch let validationError as WorkspaceValidationError {
            throw WorkspaceImportExportError.invalidWorkspaceData(validationError.userFacingMessage)
        } catch let storageError as StorageError {
            throw WorkspaceImportExportError.invalidWorkspaceData(storageError.userFacingMessage)
        } catch {
            throw WorkspaceImportExportError.invalidWorkspaceData(error.localizedDescription)
        }

        do {
            try data.write(to: url, options: [.atomic])
        } catch {
            throw WorkspaceImportExportError.writeFailed(path: url.path, reason: error.localizedDescription)
        }
    }

    func importWorkspaces(from url: URL) throws -> WorkspaceImportResult {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw WorkspaceImportExportError.readFailed(path: url.path, reason: error.localizedDescription)
        }

        do {
            let workspaces = try migrationManager.decodeWorkspaces(from: data, using: decoder)
            try validator.validateWorkspaceCollection(workspaces)
            return WorkspaceImportResult(workspaces: workspaces, importedCount: workspaces.count)
        } catch let validationError as WorkspaceValidationError {
            throw WorkspaceImportExportError.invalidWorkspaceData(validationError.userFacingMessage)
        } catch let storageError as StorageError {
            throw WorkspaceImportExportError.invalidWorkspaceData(storageError.userFacingMessage)
        } catch {
            throw WorkspaceImportExportError.invalidWorkspaceData(error.localizedDescription)
        }
    }
}
