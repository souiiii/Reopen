import Foundation

enum WorkspaceHubEditCheckFailure: Error, CustomStringConvertible {
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
        throw WorkspaceHubEditCheckFailure.message(message)
    }
}

@main
enum WorkspaceHubEditChecks {
    @MainActor
    static func main() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ReopenWorkspaceHubEditChecks-\(UUID().uuidString)", isDirectory: true)

        defer {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }

        let store = makeStore(directory: temporaryDirectory)
        let manager = WorkspaceManager(workspaceStore: store)
        let appState = AppState()

        manager.onWorkspacesChanged = { workspaces in
            appState.replaceWorkspaces(workspaces)
        }

        try inlineEditCancelDoesNotPersist(manager: manager, store: store)
        try inlineEditSavesThroughManagerAndRefreshes(
            manager: manager,
            store: store,
            appState: appState
        )
        try invalidInlineEditShowsValidationAndKeepsDraft(manager: manager)

        print("Workspace hub edit checks passed.")
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
    private static func inlineEditCancelDoesNotPersist(
        manager: WorkspaceManager,
        store: WorkspaceStore
    ) throws {
        let original = try manager.createWorkspace(sampleWorkspace(name: "Cancel Me"))
        let state = WorkspaceHubState()

        state.startEditing(workspace: original)
        state.editDraft.name = "Unsaved"
        state.editDraft.actions.removeAll()
        state.cancelEditing()

        try check(manager.getWorkspace(id: original.id) == original, "Cancel should not change manager state.")
        try check(store.loadWorkspaces().workspaces.contains(original), "Cancel should not change stored workspace data.")
        try check(state.editDraft == WorkspaceCreationDraft(), "Cancel should clear the edit draft.")
    }

    @MainActor
    private static func inlineEditSavesThroughManagerAndRefreshes(
        manager: WorkspaceManager,
        store: WorkspaceStore,
        appState: AppState
    ) throws {
        let original = try manager.createWorkspace(sampleWorkspace(name: "Editable"))
        let state = WorkspaceHubState()

        state.startEditing(workspace: original)
        state.editDraft.name = "Edited"
        state.editDraft.description = "  Updated from hub  "
        state.editDraft.isWindowRestoreEnabled = false
        state.editDraft.actions[0].displayTitle = "Updated Example"
        state.editDraft.actions.append(WorkspaceActionDraft(
            kind: .terminalCommand,
            name: "Dev",
            command: "npm run dev",
            workingDirectory: "/Users/me/Project",
            requiresConfirmation: false
        ))
        state.editDraft.windowLayouts = [
            WindowLayout(
                appBundleIdentifier: "com.example.App",
                windowTitle: "Main",
                x: 10,
                y: 20,
                width: 800,
                height: 600
            )
        ]

        WorkspaceHubEditCoordinator.saveEditDraft(
            state: state,
            workspaceManager: manager
        )

        guard let savedWorkspace = manager.getWorkspace(id: original.id) else {
            throw WorkspaceHubEditCheckFailure.message("Edited workspace was not found.")
        }

        try check(savedWorkspace.name == "Edited", "Inline edit should save the workspace name.")
        try check(savedWorkspace.description == "Updated from hub", "Inline edit should trim descriptions.")
        try check(savedWorkspace.createdAt == original.createdAt, "Inline edit should preserve createdAt.")
        try check(savedWorkspace.actions.count == 2, "Inline edit should preserve existing actions and append new ones.")
        try check(savedWorkspace.windowLayouts.count == 1, "Inline edit should preserve captured window layouts.")
        try check(!savedWorkspace.isWindowRestoreEnabled, "Inline edit should save the window restore toggle.")
        try check(state.mode == .list, "Successful inline edit should return to the list.")
        try check(state.editDraft == WorkspaceCreationDraft(), "Successful inline edit should clear the edit draft.")
        try check(state.selectedWorkspaceID == savedWorkspace.id, "Successful inline edit should select the saved workspace.")
        try check(state.expandedWorkspaceID == savedWorkspace.id, "Successful inline edit should expand the saved workspace.")
        try check(store.loadWorkspaces().workspaces.contains(savedWorkspace), "Inline edit should persist through WorkspaceStore.")
        try check(appState.workspaces.contains(savedWorkspace), "Inline edit should refresh app state immediately.")

        switch savedWorkspace.actions.first {
        case .openURL(let action):
            try check(action.displayTitle == "Updated Example", "Inline edit should preserve edited action details.")
        default:
            throw WorkspaceHubEditCheckFailure.message("Expected URL action to be preserved.")
        }
    }

    @MainActor
    private static func invalidInlineEditShowsValidationAndKeepsDraft(manager: WorkspaceManager) throws {
        let original = try manager.createWorkspace(sampleWorkspace(name: "Invalid Edit"))
        let state = WorkspaceHubState()

        state.startEditing(workspace: original)
        state.editDraft.actions = [
            WorkspaceActionDraft(
                kind: .openURL,
                url: "   "
            )
        ]

        WorkspaceHubEditCoordinator.saveEditDraft(
            state: state,
            workspaceManager: manager
        )

        try check(state.mode == .editing(workspaceID: original.id), "Invalid inline edit should keep edit mode open.")
        try check(state.editDraft.id == original.id, "Invalid inline edit should preserve the draft.")
        try check(state.validationMessage(for: .workspace(original.id)) != nil, "Invalid inline edit should show inline validation.")
        try check(manager.getWorkspace(id: original.id) == original, "Invalid inline edit should not save.")
    }

    private static func sampleWorkspace(name: String) -> Workspace {
        Workspace(
            name: name,
            description: "Original",
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
