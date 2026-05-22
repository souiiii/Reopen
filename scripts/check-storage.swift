import Foundation

enum StorageCheckFailure: Error, CustomStringConvertible {
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
        throw StorageCheckFailure.message(message)
    }
}

@main
enum StorageChecks {
    static func main() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ReopenStorageChecks-\(UUID().uuidString)", isDirectory: true)

        defer {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }

        let storageManager = StorageManager(applicationSupportDirectory: temporaryDirectory)
        let store = makeStore(storageManager: storageManager)

        try missingFileLoadsAsEmptyStore(store: store, storageManager: storageManager)
        try workspacesPersistAfterSave(store: store)
        try backupIsCreatedBeforeOverwrite(store: store, storageManager: storageManager)
        try corruptedJSONLoadsSafely(storageManager: storageManager)
        try legacyArrayJSONMigrates(storageManager: storageManager)

        print("Storage checks passed.")
    }

    private static func makeStore(storageManager: StorageManager) -> WorkspaceStore {
        WorkspaceStore(
            storageManager: storageManager,
            migrationManager: MigrationManager(),
            backupManager: JSONBackupManager(storageManager: storageManager)
        )
    }

    private static func sampleWorkspace(name: String) -> Workspace {
        Workspace(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            name: name,
            actions: [
                .openURL(OpenURLAction(
                    id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                    url: "https://example.com",
                    displayTitle: "Example"
                ))
            ],
            createdAt: Date(timeIntervalSinceReferenceDate: 100),
            updatedAt: Date(timeIntervalSinceReferenceDate: 200)
        )
    }

    private static func missingFileLoadsAsEmptyStore(
        store: WorkspaceStore,
        storageManager: StorageManager
    ) throws {
        let result = store.loadWorkspaces()

        try check(result.workspaces.isEmpty, "Missing workspaces.json should load as an empty workspace list.")
        try check(result.storageError == nil, "Missing workspaces.json should not be treated as a storage error.")
        try check(
            FileManager.default.fileExists(atPath: storageManager.applicationSupportDirectory.path),
            "Loading should create the Application Support directory."
        )
    }

    private static func workspacesPersistAfterSave(store: WorkspaceStore) throws {
        let workspace = sampleWorkspace(name: "Coding")

        try store.saveWorkspaces([workspace])
        let result = store.loadWorkspaces()

        try check(result.storageError == nil, "Saved workspace data should reload without a storage error.")
        try check(result.workspaces == [workspace], "Saved workspace data did not persist after reload.")
    }

    private static func backupIsCreatedBeforeOverwrite(
        store: WorkspaceStore,
        storageManager: StorageManager
    ) throws {
        let originalWorkspace = sampleWorkspace(name: "Coding")
        let updatedWorkspace = sampleWorkspace(name: "Writing")

        try store.saveWorkspaces([originalWorkspace])
        try store.saveWorkspaces([updatedWorkspace])

        let backupURLs = try FileManager.default.contentsOfDirectory(
            at: storageManager.backupsDirectoryURL,
            includingPropertiesForKeys: nil
        )

        try check(!backupURLs.isEmpty, "Saving over existing workspace data should create a backup.")

        let backupData = try Data(contentsOf: backupURLs[0])
        let backupWorkspaces = try MigrationManager().decodeWorkspaces(from: backupData, using: JSONDecoder())

        try check(
            backupWorkspaces == [originalWorkspace],
            "Backup should preserve the previous workspace data before overwrite."
        )

        let currentResult = store.loadWorkspaces()
        try check(currentResult.workspaces == [updatedWorkspace], "Current file should contain the updated workspace data.")
    }

    private static func corruptedJSONLoadsSafely(storageManager: StorageManager) throws {
        let store = makeStore(storageManager: storageManager)
        try storageManager.ensureApplicationSupportDirectory()
        try Data("{not valid json".utf8).write(to: storageManager.workspacesFileURL, options: [.atomic])

        let result = store.loadWorkspaces()

        try check(result.workspaces.isEmpty, "Corrupted JSON should return an empty workspace list.")
        try check(result.storageError != nil, "Corrupted JSON should return a storage error.")
    }

    private static func legacyArrayJSONMigrates(storageManager: StorageManager) throws {
        let store = makeStore(storageManager: storageManager)
        let legacyWorkspace = sampleWorkspace(name: "Legacy")
        let data = try JSONEncoder().encode([legacyWorkspace])

        try storageManager.ensureApplicationSupportDirectory()
        try data.write(to: storageManager.workspacesFileURL, options: [.atomic])

        let result = store.loadWorkspaces()

        try check(result.storageError == nil, "Legacy workspace array JSON should migrate without error.")
        try check(result.workspaces == [legacyWorkspace], "Legacy workspace array JSON did not load correctly.")
    }
}
