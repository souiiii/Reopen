import Foundation

enum WorkspaceManagerCheckFailure: Error, CustomStringConvertible {
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
        throw WorkspaceManagerCheckFailure.message(message)
    }
}

@main
enum WorkspaceManagerChecks {
    @MainActor
    static func main() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ReopenWorkspaceManagerChecks-\(UUID().uuidString)", isDirectory: true)

        defer {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }

        let store = makeStore(directory: temporaryDirectory)
        let manager = WorkspaceManager(workspaceStore: store)

        try createWorkspaceSavesImmediately(manager: manager, store: store)
        try updateWorkspaceSavesImmediately(manager: manager, store: store)
        try duplicateWorkspaceCreatesUniqueIDs(manager: manager, store: store)
        try deleteRequiresConfirmation(manager: manager)
        try deleteWorkspaceSavesImmediately(manager: manager, store: store)
        try reorderWorkspacesSavesImmediately(manager: manager, store: store)
        try blankWorkspaceNamesAreGenerated(manager: manager, store: store)
        try invalidWorkspaceDataIsRejected(manager: manager)
        try duplicateWorkspaceIDsAreRejected(manager: manager)
        try publishedChangesAreEmitted(store: store)

        print("Workspace manager checks passed.")
    }

    private static func makeStore(directory: URL) -> WorkspaceStore {
        let storageManager = StorageManager(applicationSupportDirectory: directory)
        return WorkspaceStore(
            storageManager: storageManager,
            migrationManager: MigrationManager(),
            backupManager: JSONBackupManager(storageManager: storageManager)
        )
    }

    private static func sampleWorkspace(
        id: UUID = UUID(),
        name: String,
        url: String = "https://example.com"
    ) -> Workspace {
        Workspace(
            id: id,
            name: name,
            actions: [
                .openURL(OpenURLAction(url: url, displayTitle: "Example"))
            ],
            createdAt: Date(timeIntervalSinceReferenceDate: 100),
            updatedAt: Date(timeIntervalSinceReferenceDate: 200)
        )
    }

    @MainActor
    private static func createWorkspaceSavesImmediately(
        manager: WorkspaceManager,
        store: WorkspaceStore
    ) throws {
        let created = try manager.createWorkspace(name: "Coding")

        try check(manager.getWorkspace(id: created.id) == created, "Created workspace should be available by ID.")
        try check(store.loadWorkspaces().workspaces == [created], "Created workspace should be saved immediately.")
    }

    @MainActor
    private static func updateWorkspaceSavesImmediately(
        manager: WorkspaceManager,
        store: WorkspaceStore
    ) throws {
        guard var workspace = manager.getAllWorkspaces().first else {
            throw WorkspaceManagerCheckFailure.message("Expected an existing workspace to update.")
        }

        workspace.name = "Coding Updated"
        workspace.updatedAt = Date(timeIntervalSinceReferenceDate: 300)
        let updated = try manager.updateWorkspace(workspace)

        try check(updated.name == "Coding Updated", "Updated workspace should be returned.")
        try check(store.loadWorkspaces().workspaces.first?.name == "Coding Updated", "Updated workspace should be saved immediately.")
    }

    @MainActor
    private static func duplicateWorkspaceCreatesUniqueIDs(
        manager: WorkspaceManager,
        store: WorkspaceStore
    ) throws {
        guard let original = manager.getAllWorkspaces().first else {
            throw WorkspaceManagerCheckFailure.message("Expected an existing workspace to duplicate.")
        }

        let duplicate = try manager.duplicateWorkspace(id: original.id)
        let workspaces = manager.getAllWorkspaces()
        let workspaceIDs = Set(workspaces.map(\.id))

        try check(duplicate.id != original.id, "Duplicated workspace should receive a new ID.")
        try check(duplicate.name == "Coding Updated Copy", "Duplicated workspace should receive a copy name.")
        try check(workspaceIDs.count == workspaces.count, "No duplicate workspace IDs should exist after duplication.")
        try check(store.loadWorkspaces().workspaces.count == workspaces.count, "Duplicated workspace should be saved immediately.")

        if let originalActionID = original.actions.first?.id, let duplicateActionID = duplicate.actions.first?.id {
            try check(originalActionID != duplicateActionID, "Duplicated actions should receive new IDs.")
        }
    }

    @MainActor
    private static func deleteRequiresConfirmation(manager: WorkspaceManager) throws {
        guard let workspace = manager.getAllWorkspaces().first else {
            throw WorkspaceManagerCheckFailure.message("Expected an existing workspace for delete confirmation check.")
        }

        do {
            try manager.deleteWorkspace(id: workspace.id, confirmed: false)
            throw WorkspaceManagerCheckFailure.message("Delete without confirmation should fail.")
        } catch WorkspaceManagerError.deleteRequiresConfirmation {
        } catch {
            throw WorkspaceManagerCheckFailure.message("Expected deleteRequiresConfirmation, got \(error).")
        }
    }

    @MainActor
    private static func deleteWorkspaceSavesImmediately(
        manager: WorkspaceManager,
        store: WorkspaceStore
    ) throws {
        guard let workspace = manager.getAllWorkspaces().last else {
            throw WorkspaceManagerCheckFailure.message("Expected an existing workspace to delete.")
        }

        try manager.deleteWorkspace(id: workspace.id, confirmed: true)

        try check(manager.getWorkspace(id: workspace.id) == nil, "Deleted workspace should be removed from manager.")
        try check(!store.loadWorkspaces().workspaces.contains(where: { $0.id == workspace.id }), "Deleted workspace should be removed from storage immediately.")
    }

    @MainActor
    private static func reorderWorkspacesSavesImmediately(
        manager: WorkspaceManager,
        store: WorkspaceStore
    ) throws {
        let first = try manager.createWorkspace(name: "Writing")
        let second = try manager.createWorkspace(name: "Research")

        try manager.reorderWorkspaces(ids: [second.id, first.id] + manager.getAllWorkspaces()
            .map(\.id)
            .filter { $0 != first.id && $0 != second.id })

        let storedIDs = store.loadWorkspaces().workspaces.map(\.id)
        try check(storedIDs.first == second.id, "Reordered workspaces should be saved immediately.")
        try check(storedIDs.dropFirst().first == first.id, "Reordered workspace order should be preserved.")
    }

    @MainActor
    private static func blankWorkspaceNamesAreGenerated(
        manager: WorkspaceManager,
        store: WorkspaceStore
    ) throws {
        let first = try manager.createWorkspace(name: "   ")
        let custom = try manager.createWorkspace(name: "Workspace 2")
        let second = try manager.createWorkspace(name: "")

        try check(first.name == "Workspace 1", "First blank workspace should be named Workspace 1.")
        try check(custom.name == "Workspace 2", "Existing custom names should not be overwritten.")
        try check(second.name == "Workspace 3", "Auto-generated names should skip existing Workspace N names.")
        try check(
            store.loadWorkspaces().workspaces.contains(where: { $0.id == second.id && $0.name == "Workspace 3" }),
            "Auto-generated workspace names should be saved immediately."
        )

        var edited = second
        edited.name = "   "
        let updated = try manager.updateWorkspace(edited)
        try check(updated.name == "Workspace 3", "Blank edited workspace names should be regenerated without collisions.")
    }

    @MainActor
    private static func invalidWorkspaceDataIsRejected(manager: WorkspaceManager) throws {
        let invalidAction = Workspace(
            name: "Invalid Action",
            actions: [.openURL(OpenURLAction(url: "   "))]
        )

        do {
            _ = try manager.createWorkspace(invalidAction)
            throw WorkspaceManagerCheckFailure.message("Invalid action data should be rejected.")
        } catch WorkspaceManagerError.invalidWorkspace(.emptyActionField) {
        } catch {
            throw WorkspaceManagerCheckFailure.message("Expected invalid action field, got \(error).")
        }
    }

    @MainActor
    private static func duplicateWorkspaceIDsAreRejected(manager: WorkspaceManager) throws {
        guard let existing = manager.getAllWorkspaces().first else {
            throw WorkspaceManagerCheckFailure.message("Expected an existing workspace for duplicate ID check.")
        }

        do {
            _ = try manager.createWorkspace(sampleWorkspace(id: existing.id, name: "Duplicate ID"))
            throw WorkspaceManagerCheckFailure.message("Duplicate workspace ID should be rejected.")
        } catch WorkspaceManagerError.duplicateWorkspaceID {
        } catch {
            throw WorkspaceManagerCheckFailure.message("Expected duplicateWorkspaceID, got \(error).")
        }
    }

    @MainActor
    private static func publishedChangesAreEmitted(store: WorkspaceStore) throws {
        let manager = WorkspaceManager(workspaceStore: store)
        var publishedWorkspaceCounts: [Int] = []
        manager.onWorkspacesChanged = { workspaces in
            publishedWorkspaceCounts.append(workspaces.count)
        }

        _ = try manager.createWorkspace(name: "Published")

        try check(publishedWorkspaceCounts == [1], "Workspace manager should publish changed workspace lists.")
    }
}
