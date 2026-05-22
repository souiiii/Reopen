import Foundation

struct WorkspaceStorageEnvelope: Codable, Equatable {
    static let currentSchemaVersion = 1

    var schemaVersion: Int
    var workspaces: [Workspace]

    init(schemaVersion: Int = Self.currentSchemaVersion, workspaces: [Workspace]) {
        self.schemaVersion = schemaVersion
        self.workspaces = workspaces
    }
}

final class MigrationManager {
    func decodeWorkspaces(from data: Data, using decoder: JSONDecoder) throws -> [Workspace] {
        if data.isEmpty {
            return []
        }

        do {
            let envelope = try decoder.decode(WorkspaceStorageEnvelope.self, from: data)
            return try migrate(envelope)
        } catch let storageError as StorageError {
            throw storageError
        } catch {
            do {
                return try decoder.decode([Workspace].self, from: data)
            } catch {
                throw StorageError.corruptedWorkspaceData(
                    path: "workspaces.json",
                    reason: error.localizedDescription
                )
            }
        }
    }

    func encodeWorkspaces(_ workspaces: [Workspace], using encoder: JSONEncoder) throws -> Data {
        try encoder.encode(WorkspaceStorageEnvelope(workspaces: workspaces))
    }

    private func migrate(_ envelope: WorkspaceStorageEnvelope) throws -> [Workspace] {
        switch envelope.schemaVersion {
        case WorkspaceStorageEnvelope.currentSchemaVersion:
            return envelope.workspaces
        default:
            throw StorageError.migrationFailed(
                reason: "Unsupported workspace schema version \(envelope.schemaVersion)."
            )
        }
    }
}
