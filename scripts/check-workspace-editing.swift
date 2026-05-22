import Foundation

enum WorkspaceEditingCheckFailure: Error, CustomStringConvertible {
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
        throw WorkspaceEditingCheckFailure.message(message)
    }
}

@main
enum WorkspaceEditingChecks {
    @MainActor
    static func main() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ReopenWorkspaceEditingChecks-\(UUID().uuidString)", isDirectory: true)

        defer {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }

        let storageManager = StorageManager(applicationSupportDirectory: temporaryDirectory)
        let store = WorkspaceStore(
            storageManager: storageManager,
            migrationManager: MigrationManager(),
            backupManager: JSONBackupManager(storageManager: storageManager)
        )
        let manager = WorkspaceManager(workspaceStore: store)

        try existingWorkspaceLoadsIntoDraft(manager: manager)
        try cancelDoesNotModifySavedData(manager: manager, store: store)
        try editFieldsActionsAndReorderSaveImmediately(manager: manager, store: store)

        print("Workspace editing checks passed.")
    }

    private static func sampleWorkspace() -> Workspace {
        Workspace(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            name: "Coding",
            icon: "curlybraces",
            color: "blue",
            description: "Original setup",
            actions: [
                .openURL(OpenURLAction(
                    id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                    url: "https://github.com/example/project",
                    displayTitle: "GitHub"
                )),
                .terminalCommand(TerminalCommandAction(
                    id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
                    name: "Dev Server",
                    command: "npm run dev",
                    workingDirectory: "/Users/me/Projects/App"
                )),
                .openVSCodeProject(OpenVSCodeProjectAction(
                    id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
                    projectPath: "/Users/me/Projects/App"
                ))
            ],
            windowLayouts: [
                WindowLayout(
                    id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
                    appBundleIdentifier: "com.microsoft.VSCode",
                    x: 0,
                    y: 0,
                    width: 600,
                    height: 900
                )
            ],
            createdAt: Date(timeIntervalSinceReferenceDate: 100),
            updatedAt: Date(timeIntervalSinceReferenceDate: 200)
        )
    }

    @MainActor
    private static func existingWorkspaceLoadsIntoDraft(manager: WorkspaceManager) throws {
        let workspace = try manager.createWorkspace(sampleWorkspace())
        let draft = WorkspaceCreationDraft(workspace: workspace)

        try check(draft.id == workspace.id, "Edit draft should preserve workspace ID.")
        try check(draft.name == workspace.name, "Edit draft should load workspace name.")
        try check(draft.icon == workspace.icon, "Edit draft should load workspace icon.")
        try check(draft.color == workspace.color, "Edit draft should load workspace color.")
        try check(draft.description == workspace.description, "Edit draft should load workspace description.")
        try check(draft.actions.count == workspace.actions.count, "Edit draft should load workspace actions.")
        try check(draft.windowLayouts == workspace.windowLayouts, "Edit draft should preserve window layouts.")
    }

    @MainActor
    private static func cancelDoesNotModifySavedData(
        manager: WorkspaceManager,
        store: WorkspaceStore
    ) throws {
        guard let workspace = manager.getAllWorkspaces().first else {
            throw WorkspaceEditingCheckFailure.message("Expected a workspace for cancel check.")
        }

        var draft = WorkspaceCreationDraft(workspace: workspace)
        draft.name = "Unsaved Rename"
        draft.actions.removeAll()

        let storedBeforeSave = store.loadWorkspaces().workspaces

        try check(
            storedBeforeSave == manager.getAllWorkspaces(),
            "Mutating an edit draft without saving should not change stored workspaces."
        )
        try check(
            manager.getWorkspace(id: workspace.id)?.name == "Coding",
            "Mutating an edit draft without saving should not change manager state."
        )
    }

    @MainActor
    private static func editFieldsActionsAndReorderSaveImmediately(
        manager: WorkspaceManager,
        store: WorkspaceStore
    ) throws {
        guard let original = manager.getAllWorkspaces().first else {
            throw WorkspaceEditingCheckFailure.message("Expected a workspace to edit.")
        }

        var draft = WorkspaceCreationDraft(workspace: original)
        draft.name = "Coding Updated"
        draft.icon = "briefcase"
        draft.color = "green"
        draft.description = "Updated setup"

        guard draft.actions.count == 3 else {
            throw WorkspaceEditingCheckFailure.message("Expected three actions in edit draft.")
        }

        draft.actions[0].url = "https://github.com/example/updated"
        draft.actions[0].displayTitle = "Updated GitHub"
        draft.actions.swapAt(0, 2)
        draft.actions.remove(at: 1)

        let editedWorkspace = try draft.makeWorkspace()
        let savedWorkspace = try manager.updateWorkspace(editedWorkspace)
        let storedWorkspace = try checkStoredWorkspace(store: store, id: original.id)

        try check(savedWorkspace.id == original.id, "Editing should preserve the workspace ID.")
        try check(savedWorkspace.createdAt == original.createdAt, "Editing should preserve createdAt.")
        try check(savedWorkspace.updatedAt != original.updatedAt, "Editing should update updatedAt.")
        try check(savedWorkspace.name == "Coding Updated", "Workspace rename should save.")
        try check(savedWorkspace.icon == "briefcase", "Workspace icon change should save.")
        try check(savedWorkspace.color == "green", "Workspace color change should save.")
        try check(savedWorkspace.description == "Updated setup", "Workspace description change should save.")
        try check(savedWorkspace.actions.count == 2, "Action deletion should save.")
        try check(savedWorkspace.windowLayouts == original.windowLayouts, "Editing should preserve existing window layouts.")
        try check(storedWorkspace == savedWorkspace, "Saved edit should persist immediately.")

        switch savedWorkspace.actions.first {
        case .openVSCodeProject:
            break
        default:
            throw WorkspaceEditingCheckFailure.message("Action reorder should persist.")
        }

        switch savedWorkspace.actions.last {
        case .openURL(let action):
            try check(action.url == "https://github.com/example/updated", "Action field edits should persist.")
            try check(action.displayTitle == "Updated GitHub", "Action title edits should persist.")
        default:
            throw WorkspaceEditingCheckFailure.message("Edited URL action should still exist after reorder/delete.")
        }
    }

    private static func checkStoredWorkspace(store: WorkspaceStore, id: UUID) throws -> Workspace {
        let workspaces = store.loadWorkspaces().workspaces
        guard let workspace = workspaces.first(where: { $0.id == id }) else {
            throw WorkspaceEditingCheckFailure.message("Stored workspace could not be found.")
        }

        return workspace
    }
}
