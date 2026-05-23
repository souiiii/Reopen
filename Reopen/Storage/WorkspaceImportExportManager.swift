import Foundation

struct ImportedWorkspaceSummary: Equatable, Identifiable {
    var id: UUID { importedID }
    var name: String
    var originalID: UUID
    var importedID: UUID

    var didRegenerateID: Bool {
        originalID != importedID
    }
}

struct WorkspaceImportSummary: Equatable {
    var importedWorkspaces: [ImportedWorkspaceSummary]

    var importedCount: Int {
        importedWorkspaces.count
    }

    var regeneratedIDCount: Int {
        importedWorkspaces.filter(\.didRegenerateID).count
    }

    var summaryText: String {
        if importedWorkspaces.isEmpty {
            return "No workspaces were added."
        }

        let noun = importedCount == 1 ? "workspace" : "workspaces"
        let names = importedWorkspaces.map(\.name).joined(separator: ", ")

        if regeneratedIDCount > 0 {
            let regeneratedNoun = regeneratedIDCount == 1 ? "duplicate ID" : "duplicate IDs"
            return "Imported \(importedCount) \(noun): \(names). Regenerated \(regeneratedIDCount) \(regeneratedNoun)."
        }

        return "Imported \(importedCount) \(noun): \(names)."
    }
}

struct WorkspaceImportResult: Equatable {
    var workspaces: [Workspace]
    var summary: WorkspaceImportSummary

    var importedCount: Int {
        summary.importedCount
    }
}

enum WorkspaceImportExportError: Error, Equatable {
    case readFailed(path: String, reason: String)
    case writeFailed(path: String, reason: String)
    case invalidWorkspaceData(String)
    case unsafeImportFile(String)

    var userFacingMessage: String {
        switch self {
        case .readFailed:
            return "Import failed because Reopen could not read the selected file."
        case .writeFailed:
            return "Export failed because Reopen could not write the selected file."
        case .invalidWorkspaceData(let reason):
            return "Import failed: \(reason)"
        case .unsafeImportFile(let reason):
            return "Import rejected: \(reason)"
        }
    }
}

final class WorkspaceImportExportManager {
    private let migrationManager: MigrationManager
    private let validator: WorkspaceValidator
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let maxImportFileSize: Int

    init(
        migrationManager: MigrationManager = MigrationManager(),
        validator: WorkspaceValidator = WorkspaceValidator(),
        maxImportFileSize: Int = 5_000_000
    ) {
        self.migrationManager = migrationManager
        self.validator = validator
        self.maxImportFileSize = maxImportFileSize

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder

        self.decoder = JSONDecoder()
    }

    func exportWorkspaces(_ workspaces: [Workspace], to url: URL) throws {
        try exportValidatedWorkspaces(workspaces, to: url)
    }

    func exportWorkspace(_ workspace: Workspace, to url: URL) throws {
        try exportValidatedWorkspaces([workspace], to: url)
    }

    func importWorkspaces(from url: URL, existingWorkspaces: [Workspace] = []) throws -> WorkspaceImportResult {
        let data = try readSafeImportData(from: url)

        do {
            let decodedWorkspaces = try decodeImportedWorkspaces(from: data)
            let normalizedWorkspaces = try normalizedImportedWorkspaces(
                decodedWorkspaces,
                existingWorkspaces: existingWorkspaces
            )

            try validator.validateWorkspaceCollection(existingWorkspaces + normalizedWorkspaces.workspaces)

            return WorkspaceImportResult(
                workspaces: normalizedWorkspaces.workspaces,
                summary: WorkspaceImportSummary(importedWorkspaces: normalizedWorkspaces.summaries)
            )
        } catch let importError as WorkspaceImportExportError {
            throw importError
        } catch let validationError as WorkspaceValidationError {
            throw WorkspaceImportExportError.invalidWorkspaceData(validationError.userFacingMessage)
        } catch let storageError as StorageError {
            throw WorkspaceImportExportError.invalidWorkspaceData(storageError.userFacingMessage)
        } catch {
            throw WorkspaceImportExportError.invalidWorkspaceData(error.localizedDescription)
        }
    }

    private func exportValidatedWorkspaces(_ workspaces: [Workspace], to url: URL) throws {
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

    private func readSafeImportData(from url: URL) throws -> Data {
        guard url.isFileURL else {
            throw WorkspaceImportExportError.unsafeImportFile("Only local JSON files can be imported.")
        }

        guard url.pathExtension.lowercased() == "json" else {
            throw WorkspaceImportExportError.unsafeImportFile("Choose a .json file exported from Reopen.")
        }

        do {
            let values = try url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey])
            if values.isDirectory == true {
                throw WorkspaceImportExportError.unsafeImportFile("Folders cannot be imported.")
            }

            if let fileSize = values.fileSize, fileSize > maxImportFileSize {
                throw WorkspaceImportExportError.unsafeImportFile("The selected file is too large.")
            }
        } catch {
            if let importError = error as? WorkspaceImportExportError {
                throw importError
            }

            throw WorkspaceImportExportError.readFailed(path: url.path, reason: error.localizedDescription)
        }

        do {
            return try Data(contentsOf: url)
        } catch {
            throw WorkspaceImportExportError.readFailed(path: url.path, reason: error.localizedDescription)
        }
    }

    private func decodeImportedWorkspaces(from data: Data) throws -> [Workspace] {
        guard !data.isEmpty else {
            throw WorkspaceImportExportError.invalidWorkspaceData("The selected file is empty.")
        }

        do {
            return try migrationManager.decodeWorkspaces(from: data, using: decoder)
        } catch {
            do {
                return [try decoder.decode(Workspace.self, from: data)]
            } catch {
                throw WorkspaceImportExportError.invalidWorkspaceData("The selected file is not valid workspace JSON.")
            }
        }
    }

    private func normalizedImportedWorkspaces(
        _ importedWorkspaces: [Workspace],
        existingWorkspaces: [Workspace]
    ) throws -> (workspaces: [Workspace], summaries: [ImportedWorkspaceSummary]) {
        var usedWorkspaceIDs = Set(existingWorkspaces.map(\.id))
        var normalizedWorkspaces: [Workspace] = []
        var summaries: [ImportedWorkspaceSummary] = []

        for workspace in importedWorkspaces {
            try validator.validateWorkspace(workspace)

            let originalID = workspace.id
            var importedWorkspace = workspace

            if usedWorkspaceIDs.contains(importedWorkspace.id) {
                importedWorkspace = workspace.replacingID(UUID())
            }

            while usedWorkspaceIDs.contains(importedWorkspace.id) {
                importedWorkspace = importedWorkspace.replacingID(UUID())
            }

            usedWorkspaceIDs.insert(importedWorkspace.id)
            normalizedWorkspaces.append(importedWorkspace)
            summaries.append(ImportedWorkspaceSummary(
                name: importedWorkspace.name,
                originalID: originalID,
                importedID: importedWorkspace.id
            ))
        }

        return (normalizedWorkspaces, summaries)
    }
}

private extension Workspace {
    func replacingID(_ id: UUID) -> Workspace {
        Workspace(
            id: id,
            name: name,
            icon: icon,
            color: color,
            description: description,
            actions: actions,
            windowLayouts: windowLayouts,
            isWindowRestoreEnabled: isWindowRestoreEnabled,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }
}
