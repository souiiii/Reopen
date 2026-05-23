import Foundation

enum WorkspaceValidationError: Error, Equatable {
    case emptyName
    case duplicateWorkspaceID(UUID)
    case emptyActionField(actionID: UUID, field: String)
    case duplicateActionID(UUID)
    case emptyWindowLayoutBundleIdentifier(UUID)
    case invalidWindowLayoutFrame(UUID)

    var userFacingMessage: String {
        switch self {
        case .emptyName:
            return "Blank workspace names are named automatically."
        case .duplicateWorkspaceID:
            return "Every workspace must have a unique ID."
        case .emptyActionField(_, let field):
            return "Workspace action is missing \(field)."
        case .duplicateActionID:
            return "Every workspace action must have a unique ID."
        case .emptyWindowLayoutBundleIdentifier:
            return "Window layouts must include an app bundle identifier."
        case .invalidWindowLayoutFrame:
            return "Window layouts must have a valid size."
        }
    }
}

final class WorkspaceValidator {
    func validateWorkspace(_ workspace: Workspace) throws {
        try validateActions(workspace.actions)
        try validateWindowLayouts(workspace.windowLayouts)
    }

    func validateWorkspaceCollection(_ workspaces: [Workspace]) throws {
        var workspaceIDs = Set<UUID>()

        for workspace in workspaces {
            if workspaceIDs.contains(workspace.id) {
                throw WorkspaceValidationError.duplicateWorkspaceID(workspace.id)
            }

            workspaceIDs.insert(workspace.id)
            try validateWorkspace(workspace)
        }
    }

    private func validateActions(_ actions: [WorkspaceAction]) throws {
        var actionIDs = Set<UUID>()

        for action in actions {
            if actionIDs.contains(action.id) {
                throw WorkspaceValidationError.duplicateActionID(action.id)
            }

            actionIDs.insert(action.id)
            try validateAction(action)
        }
    }

    private func validateAction(_ action: WorkspaceAction) throws {
        switch action {
        case .openApp(let payload):
            try requireNonEmpty(payload.name, actionID: payload.id, field: "name")
            try requireNonEmpty(payload.path, actionID: payload.id, field: "path")
        case .openFile(let payload):
            try requireNonEmpty(payload.name, actionID: payload.id, field: "name")
            try requireNonEmpty(payload.path, actionID: payload.id, field: "path")
        case .openFolder(let payload):
            try requireNonEmpty(payload.name, actionID: payload.id, field: "name")
            try requireNonEmpty(payload.path, actionID: payload.id, field: "path")
        case .openURL(let payload):
            try requireNonEmpty(payload.url, actionID: payload.id, field: "url")
        case .terminalCommand(let payload):
            try requireNonEmpty(payload.name, actionID: payload.id, field: "name")
            try requireNonEmpty(payload.command, actionID: payload.id, field: "command")
            try requireNonEmpty(payload.workingDirectory, actionID: payload.id, field: "workingDirectory")
        case .openVSCodeProject(let payload):
            try requireNonEmpty(payload.projectPath, actionID: payload.id, field: "projectPath")
            try requireNonEmpty(payload.editor, actionID: payload.id, field: "editor")
        case .shellScript(let payload):
            try requireNonEmpty(payload.name, actionID: payload.id, field: "name")
            try requireNonEmpty(payload.scriptPath, actionID: payload.id, field: "scriptPath")
        }
    }

    private func validateWindowLayouts(_ layouts: [WindowLayout]) throws {
        for layout in layouts {
            guard !layout.appBundleIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw WorkspaceValidationError.emptyWindowLayoutBundleIdentifier(layout.id)
            }

            guard layout.width > 0, layout.height > 0 else {
                throw WorkspaceValidationError.invalidWindowLayoutFrame(layout.id)
            }
        }
    }

    private func requireNonEmpty(_ value: String, actionID: UUID, field: String) throws {
        guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw WorkspaceValidationError.emptyActionField(actionID: actionID, field: field)
        }
    }
}
