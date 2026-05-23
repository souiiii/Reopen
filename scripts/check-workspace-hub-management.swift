import Foundation

enum WorkspaceHubManagementCheckFailure: Error, CustomStringConvertible {
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
        throw WorkspaceHubManagementCheckFailure.message(message)
    }
}

@main
enum WorkspaceHubManagementChecks {
    @MainActor
    static func main() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ReopenWorkspaceHubManagementChecks-\(UUID().uuidString)", isDirectory: true)

        defer {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }

        let store = makeStore(directory: temporaryDirectory)
        let manager = WorkspaceManager(workspaceStore: store)
        let appState = AppState()

        manager.onWorkspacesChanged = { workspaces in
            appState.replaceWorkspaces(workspaces)
        }

        try inlineDeleteRequiresAndClearsConfirmation(
            manager: manager,
            store: store,
            appState: appState
        )
        try inlineDuplicateCreatesSelectableCopy(
            manager: manager,
            store: store,
            appState: appState
        )
        try inlineReorderPersists(
            manager: manager,
            store: store,
            appState: appState
        )

        print("Workspace hub management checks passed.")
    }

    private static func makeStore(directory: URL) -> WorkspaceStore {
        let storageManager = StorageManager(applicationSupportDirectory: directory)
        return WorkspaceStore(
            storageManager: storageManager,
            migrationManager: MigrationManager(),
            backupManager: JSONBackupManager(storageManager: storageManager)
        )
    }

    @MainActor
    private static func inlineDeleteRequiresAndClearsConfirmation(
        manager: WorkspaceManager,
        store: WorkspaceStore,
        appState: AppState
    ) throws {
        let workspace = try manager.createWorkspace(sampleWorkspace(name: "Delete Me"))
        let state = WorkspaceHubState()

        state.beginDeleteConfirmation(workspaceID: workspace.id)
        try check(state.deleteConfirmationWorkspaceID == workspace.id, "First delete click should reveal confirmation.")
        try check(manager.getWorkspace(id: workspace.id) != nil, "First delete click should not delete immediately.")

        WorkspaceHubManagementCoordinator.deleteWorkspace(
            id: workspace.id,
            state: state,
            workspaceManager: manager
        )

        try check(state.deleteConfirmationWorkspaceID == nil, "Confirmed delete should clear confirmation.")
        try check(manager.getWorkspace(id: workspace.id) == nil, "Confirmed delete should remove the workspace.")
        try check(!store.loadWorkspaces().workspaces.contains(where: { $0.id == workspace.id }), "Confirmed delete should persist.")
        try check(!appState.workspaces.contains(where: { $0.id == workspace.id }), "Confirmed delete should refresh app state.")
    }

    @MainActor
    private static func inlineDuplicateCreatesSelectableCopy(
        manager: WorkspaceManager,
        store: WorkspaceStore,
        appState: AppState
    ) throws {
        let original = try manager.createWorkspace(sampleWorkspace(name: "Duplicate Me"))
        let state = WorkspaceHubState()

        WorkspaceHubManagementCoordinator.duplicateWorkspace(
            id: original.id,
            state: state,
            workspaceManager: manager
        )

        let workspaces = manager.getAllWorkspaces()
        guard let duplicate = workspaces.last else {
            throw WorkspaceHubManagementCheckFailure.message("Expected duplicated workspace.")
        }

        try check(duplicate.id != original.id, "Duplicate should receive a new ID.")
        try check(duplicate.name == "Duplicate Me Copy", "Duplicate should receive a copy name.")
        try check(duplicate.actions.count == original.actions.count, "Duplicate should preserve actions.")
        try check(state.selectedWorkspaceID == duplicate.id, "Duplicate should select the new copy.")
        try check(state.expandedWorkspaceID == duplicate.id, "Duplicate should expand the new copy.")
        try check(store.loadWorkspaces().workspaces.contains(duplicate), "Duplicate should persist.")
        try check(appState.workspaces.contains(duplicate), "Duplicate should refresh app state.")
    }

    @MainActor
    private static func inlineReorderPersists(
        manager: WorkspaceManager,
        store: WorkspaceStore,
        appState: AppState
    ) throws {
        let first = try manager.createWorkspace(sampleWorkspace(name: "First"))
        let second = try manager.createWorkspace(sampleWorkspace(name: "Second"))
        let state = WorkspaceHubState()

        WorkspaceHubManagementCoordinator.moveWorkspace(
            id: second.id,
            offset: -1,
            state: state,
            workspaceManager: manager
        )

        try check(secondIsBeforeFirst(in: manager.getAllWorkspaces(), firstID: first.id, secondID: second.id), "Move up should reorder manager state.")
        try check(secondIsBeforeFirst(in: store.loadWorkspaces().workspaces, firstID: first.id, secondID: second.id), "Move up should persist order.")
        try check(secondIsBeforeFirst(in: appState.workspaces, firstID: first.id, secondID: second.id), "Move up should refresh app state.")
        try check(state.selectedWorkspaceID == second.id, "Move up should keep the moved workspace selected.")

        WorkspaceHubManagementCoordinator.moveWorkspace(
            id: second.id,
            offset: 1,
            state: state,
            workspaceManager: manager
        )

        try check(secondIsBeforeFirst(in: manager.getAllWorkspaces(), firstID: second.id, secondID: first.id), "Move down should reorder manager state.")
    }

    private static func secondIsBeforeFirst(
        in workspaces: [Workspace],
        firstID: UUID,
        secondID: UUID
    ) -> Bool {
        guard
            let firstIndex = workspaces.firstIndex(where: { $0.id == firstID }),
            let secondIndex = workspaces.firstIndex(where: { $0.id == secondID })
        else {
            return false
        }

        return secondIndex < firstIndex
    }

    private static func sampleWorkspace(name: String) -> Workspace {
        Workspace(
            name: name,
            actions: [
                .openURL(OpenURLAction(
                    url: "https://example.com",
                    displayTitle: "Example"
                ))
            ],
            createdAt: Date(timeIntervalSinceReferenceDate: 100),
            updatedAt: Date(timeIntervalSinceReferenceDate: 200)
        )
    }
}
