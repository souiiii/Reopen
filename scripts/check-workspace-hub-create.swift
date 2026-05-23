import Foundation

enum WorkspaceHubCreateCheckFailure: Error, CustomStringConvertible {
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
        throw WorkspaceHubCreateCheckFailure.message(message)
    }
}

@main
enum WorkspaceHubCreateChecks {
    @MainActor
    static func main() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ReopenWorkspaceHubCreateChecks-\(UUID().uuidString)", isDirectory: true)

        defer {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }

        let store = makeStore(directory: temporaryDirectory)
        let manager = WorkspaceManager(workspaceStore: store)
        let appState = AppState()

        manager.onWorkspacesChanged = { workspaces in
            appState.replaceWorkspaces(workspaces)
        }

        try inlineCreateSavesRefreshesAndResetsState(
            manager: manager,
            store: store,
            appState: appState
        )
        try invalidInlineCreateShowsValidationAndKeepsDraft(manager: manager)

        print("Workspace hub create checks passed.")
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
    private static func inlineCreateSavesRefreshesAndResetsState(
        manager: WorkspaceManager,
        store: WorkspaceStore,
        appState: AppState
    ) throws {
        let state = WorkspaceHubState()
        state.startCreating()
        state.createDraft.name = "   "
        state.createDraft.description = "  Created inside the hub  "
        state.createDraft.actions = [
            WorkspaceActionDraft(
                kind: .openURL,
                url: "example.com",
                displayTitle: "Example"
            ),
            WorkspaceActionDraft(
                kind: .terminalCommand,
                name: "Dev Server",
                command: "npm run dev",
                workingDirectory: "/Users/me/Project",
                requiresConfirmation: false
            ),
            .vsCodeProject(path: "/Users/me/Project")
        ]

        WorkspaceHubCreateCoordinator.saveCreateDraft(
            state: state,
            workspaceManager: manager
        )

        let savedWorkspaces = manager.getAllWorkspaces()
        let savedWorkspace = try checkSingleWorkspace(savedWorkspaces)

        try check(savedWorkspace.name == "Workspace 1", "Blank inline create names should be auto-generated.")
        try check(savedWorkspace.description == "Created inside the hub", "Inline create should trim descriptions.")
        try check(savedWorkspace.actions.count == 3, "Inline create should save all draft actions.")
        try check(state.mode == .list, "Successful inline create should return to the list.")
        try check(!state.isCreateComposerPresented, "Successful inline create should collapse the composer.")
        try check(state.createDraft == WorkspaceCreationDraft(), "Successful inline create should clear the draft.")
        try check(state.selectedWorkspaceID == savedWorkspace.id, "Successful inline create should select the saved workspace.")
        try check(state.expandedWorkspaceID == savedWorkspace.id, "Successful inline create should expand the saved workspace.")
        try check(state.validationMessage(for: .create) == nil, "Successful inline create should clear create errors.")
        try check(store.loadWorkspaces().workspaces == savedWorkspaces, "Inline create should persist through WorkspaceStore.")
        try check(appState.workspaces == savedWorkspaces, "Inline create should refresh app state immediately.")
    }

    @MainActor
    private static func invalidInlineCreateShowsValidationAndKeepsDraft(manager: WorkspaceManager) throws {
        let state = WorkspaceHubState()
        state.startCreating()
        state.createDraft.name = "Broken"
        state.createDraft.actions = [
            WorkspaceActionDraft(
                kind: .terminalCommand,
                name: "Broken Command",
                command: "npm run dev",
                workingDirectory: "   "
            )
        ]

        WorkspaceHubCreateCoordinator.saveCreateDraft(
            state: state,
            workspaceManager: manager
        )

        try check(state.mode == .creating, "Invalid inline create should keep the composer open.")
        try check(state.isCreateComposerPresented, "Invalid inline create should not collapse the composer.")
        try check(state.createDraft.name == "Broken", "Invalid inline create should preserve the draft.")
        try check(
            state.validationMessage(for: .create) == "Terminal Command is missing working directory.",
            "Invalid inline create should show the draft validation error inline."
        )
        try check(!manager.getAllWorkspaces().contains { $0.name == "Broken" }, "Invalid inline create should not save.")
    }

    private static func checkSingleWorkspace(_ workspaces: [Workspace]) throws -> Workspace {
        guard workspaces.count == 1, let workspace = workspaces.first else {
            throw WorkspaceHubCreateCheckFailure.message("Expected exactly one saved workspace.")
        }

        return workspace
    }
}
