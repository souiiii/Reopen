import Foundation

enum WorkspaceManagerError: Error, Equatable {
    case invalidWorkspace(WorkspaceValidationError)
    case workspaceNotFound(UUID)
    case duplicateWorkspaceID(UUID)
    case deleteRequiresConfirmation(UUID)
    case reorderIDMismatch

    var userFacingMessage: String {
        switch self {
        case .invalidWorkspace(let validationError):
            return validationError.userFacingMessage
        case .workspaceNotFound:
            return "Workspace could not be found."
        case .duplicateWorkspaceID:
            return "Every workspace must have a unique ID."
        case .deleteRequiresConfirmation:
            return "Deleting a workspace requires confirmation."
        case .reorderIDMismatch:
            return "Workspace order could not be saved because the list changed."
        }
    }
}

@MainActor
final class WorkspaceManager {
    private let workspaceStore: WorkspaceStore
    private let validator: WorkspaceValidator
    private var workspaces: [Workspace]

    var onWorkspacesChanged: (([Workspace]) -> Void)?

    init(
        workspaceStore: WorkspaceStore,
        validator: WorkspaceValidator = WorkspaceValidator(),
        initialWorkspaces: [Workspace] = []
    ) {
        self.workspaceStore = workspaceStore
        self.validator = validator
        self.workspaces = initialWorkspaces
    }

    func createWorkspace(
        name: String,
        icon: String? = nil,
        color: String? = nil,
        description: String? = nil,
        actions: [WorkspaceAction] = [],
        windowLayouts: [WindowLayout] = []
    ) throws -> Workspace {
        try createWorkspace(
            Workspace(
                name: name,
                icon: icon,
                color: color,
                description: description,
                actions: actions,
                windowLayouts: windowLayouts
            )
        )
    }

    func createWorkspace(_ workspace: Workspace) throws -> Workspace {
        guard !workspaces.contains(where: { $0.id == workspace.id }) else {
            throw WorkspaceManagerError.duplicateWorkspaceID(workspace.id)
        }

        var proposedWorkspaces = workspaces
        proposedWorkspaces.append(workspace)
        try validateAndPersist(proposedWorkspaces)
        publish(proposedWorkspaces)
        return workspace
    }

    func updateWorkspace(_ workspace: Workspace) throws -> Workspace {
        guard let index = workspaces.firstIndex(where: { $0.id == workspace.id }) else {
            throw WorkspaceManagerError.workspaceNotFound(workspace.id)
        }

        var proposedWorkspaces = workspaces
        proposedWorkspaces[index] = workspace
        try validateAndPersist(proposedWorkspaces)
        publish(proposedWorkspaces)
        return workspace
    }

    func deleteWorkspace(id: UUID, confirmed: Bool) throws {
        guard confirmed else {
            throw WorkspaceManagerError.deleteRequiresConfirmation(id)
        }

        guard workspaces.contains(where: { $0.id == id }) else {
            throw WorkspaceManagerError.workspaceNotFound(id)
        }

        let proposedWorkspaces = workspaces.filter { $0.id != id }
        try validateAndPersist(proposedWorkspaces)
        publish(proposedWorkspaces)
    }

    func duplicateWorkspace(id: UUID) throws -> Workspace {
        guard let workspace = getWorkspace(id: id) else {
            throw WorkspaceManagerError.workspaceNotFound(id)
        }

        var duplicate = workspace.duplicated()
        while workspaces.contains(where: { $0.id == duplicate.id }) {
            duplicate = duplicate.duplicated()
        }

        var proposedWorkspaces = workspaces
        proposedWorkspaces.append(duplicate)
        try validateAndPersist(proposedWorkspaces)
        publish(proposedWorkspaces)
        return duplicate
    }

    func getWorkspace(id: UUID) -> Workspace? {
        workspaces.first { $0.id == id }
    }

    func getAllWorkspaces() -> [Workspace] {
        workspaces
    }

    func reorderWorkspaces(ids orderedIDs: [UUID]) throws {
        let existingIDs = Set(workspaces.map(\.id))
        let requestedIDs = Set(orderedIDs)

        guard existingIDs == requestedIDs, orderedIDs.count == workspaces.count else {
            throw WorkspaceManagerError.reorderIDMismatch
        }

        let workspaceByID = Dictionary(uniqueKeysWithValues: workspaces.map { ($0.id, $0) })
        let proposedWorkspaces = orderedIDs.compactMap { workspaceByID[$0] }

        guard proposedWorkspaces.count == workspaces.count else {
            throw WorkspaceManagerError.reorderIDMismatch
        }

        try validateAndPersist(proposedWorkspaces)
        publish(proposedWorkspaces)
    }

    func replaceLoadedWorkspaces(_ loadedWorkspaces: [Workspace]) throws {
        try validator.validateWorkspaceCollection(loadedWorkspaces)
        publish(loadedWorkspaces)
    }

    private func validateAndPersist(_ proposedWorkspaces: [Workspace]) throws {
        do {
            try validator.validateWorkspaceCollection(proposedWorkspaces)
        } catch let validationError as WorkspaceValidationError {
            throw WorkspaceManagerError.invalidWorkspace(validationError)
        }

        try workspaceStore.saveWorkspaces(proposedWorkspaces)
    }

    private func publish(_ updatedWorkspaces: [Workspace]) {
        workspaces = updatedWorkspaces
        onWorkspacesChanged?(updatedWorkspaces)
    }
}

private extension Workspace {
    func duplicated() -> Workspace {
        Workspace(
            name: "\(name) Copy",
            icon: icon,
            color: color,
            description: description,
            actions: actions.map { $0.duplicated() },
            windowLayouts: windowLayouts.map { $0.duplicated() },
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

private extension WorkspaceAction {
    func duplicated() -> WorkspaceAction {
        switch self {
        case .openApp(let action):
            return .openApp(OpenAppAction(
                name: action.name,
                path: action.path,
                bundleIdentifier: action.bundleIdentifier
            ))
        case .openFile(let action):
            return .openFile(OpenFileAction(
                name: action.name,
                path: action.path,
                securityScopedBookmarkData: action.securityScopedBookmarkData
            ))
        case .openFolder(let action):
            return .openFolder(OpenFolderAction(
                name: action.name,
                path: action.path,
                securityScopedBookmarkData: action.securityScopedBookmarkData
            ))
        case .openURL(let action):
            return .openURL(OpenURLAction(
                url: action.url,
                displayTitle: action.displayTitle
            ))
        case .terminalCommand(let action):
            return .terminalCommand(TerminalCommandAction(
                name: action.name,
                command: action.command,
                workingDirectory: action.workingDirectory,
                requiresConfirmation: action.requiresConfirmation
            ))
        case .openVSCodeProject(let action):
            return .openVSCodeProject(OpenVSCodeProjectAction(
                projectPath: action.projectPath,
                editor: action.editor
            ))
        case .shellScript(let action):
            return .shellScript(ShellScriptAction(
                name: action.name,
                scriptPath: action.scriptPath,
                workingDirectory: action.workingDirectory,
                requiresConfirmation: action.requiresConfirmation
            ))
        }
    }
}

private extension WindowLayout {
    func duplicated() -> WindowLayout {
        WindowLayout(
            appBundleIdentifier: appBundleIdentifier,
            windowTitle: windowTitle,
            screenIdentifier: screenIdentifier,
            x: x,
            y: y,
            width: width,
            height: height
        )
    }
}
