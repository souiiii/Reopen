import Foundation

enum WorkspaceCreationCheckFailure: Error, CustomStringConvertible {
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
        throw WorkspaceCreationCheckFailure.message(message)
    }
}

@main
enum WorkspaceCreationChecks {
    @MainActor
    static func main() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ReopenWorkspaceCreationChecks-\(UUID().uuidString)", isDirectory: true)

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

        try blankNameIsAllowedAndAutoNamed(manager: manager, store: store)
        try invalidDraftActionIsRejected()
        try draftCreatesWorkspaceWithAllPhaseEightActionTypes(manager: manager, store: store)

        print("Workspace creation checks passed.")
    }

    @MainActor
    private static func blankNameIsAllowedAndAutoNamed(
        manager: WorkspaceManager,
        store: WorkspaceStore
    ) throws {
        let draft = WorkspaceCreationDraft(name: "   ")
        let workspace = try draft.makeWorkspace()
        let savedWorkspace = try manager.createWorkspace(workspace)

        try check(workspace.name.isEmpty, "Draft should allow blank names before manager auto-naming.")
        try check(draft.validationMessage == nil, "Blank draft names should not show a validation message.")
        try check(savedWorkspace.name == "Workspace 1", "Manager should auto-name blank draft workspaces.")
        try check(store.loadWorkspaces().workspaces.first?.name == "Workspace 1", "Auto-named workspace should be saved.")
    }

    private static func invalidDraftActionIsRejected() throws {
        let draft = WorkspaceCreationDraft(
            name: "Invalid",
            actions: [.url()]
        )

        do {
            _ = try draft.makeWorkspace()
            throw WorkspaceCreationCheckFailure.message("Incomplete URL action should be rejected.")
        } catch WorkspaceCreationError.invalidAction {
        } catch {
            throw WorkspaceCreationCheckFailure.message("Expected invalidAction, got \(error).")
        }
    }

    @MainActor
    private static func draftCreatesWorkspaceWithAllPhaseEightActionTypes(
        manager: WorkspaceManager,
        store: WorkspaceStore
    ) throws {
        let draft = WorkspaceCreationDraft(
            name: "Coding",
            icon: "curlybraces",
            color: "blue",
            description: "Opens my development setup",
            actions: [
                .app(
                    name: "Visual Studio Code",
                    path: "/Applications/Visual Studio Code.app",
                    bundleIdentifier: "com.microsoft.VSCode"
                ),
                .file(name: "Brief", path: "/Users/me/Documents/brief.pdf"),
                .folder(name: "Project", path: "/Users/me/Projects/App"),
                WorkspaceActionDraft(
                    kind: .openURL,
                    url: "https://github.com/example/project",
                    displayTitle: "GitHub"
                ),
                WorkspaceActionDraft(
                    kind: .terminalCommand,
                    name: "Dev Server",
                    command: "npm run dev",
                    workingDirectory: "/Users/me/Projects/App"
                ),
                .vsCodeProject(path: "/Users/me/Projects/App")
            ]
        )

        let workspace = try draft.makeWorkspace()
        let savedWorkspace = try manager.createWorkspace(workspace)
        let storedWorkspaces = store.loadWorkspaces().workspaces

        try check(savedWorkspace.name == "Coding", "Created workspace should preserve the draft name.")
        try check(savedWorkspace.actions.count == 6, "Created workspace should include all Phase 8 action types.")
        try check(storedWorkspaces.contains(savedWorkspace), "Created workspace should save immediately.")
        try check(manager.getWorkspace(id: savedWorkspace.id) == savedWorkspace, "Created workspace should appear in the manager immediately.")
    }
}
