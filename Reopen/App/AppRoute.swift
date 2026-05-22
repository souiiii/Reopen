import Foundation

enum AppRoute: Hashable {
    case createWorkspace
    case manageWorkspaces
    case settings
    case launchWorkspace(String)

    var title: String {
        switch self {
        case .createWorkspace:
            return "Create Workspace"
        case .manageWorkspaces:
            return "Manage Workspaces"
        case .settings:
            return "Settings"
        case .launchWorkspace(let workspaceName):
            return "Launch \(workspaceName)"
        }
    }

    var placeholderMessage: String {
        switch self {
        case .createWorkspace:
            return "Workspace creation will be implemented in Phase 8."
        case .manageWorkspaces:
            return "Workspace management will be implemented in Phase 7 and Phase 9."
        case .settings:
            return "Settings will be implemented in Phase 18."
        case .launchWorkspace:
            return "Workspace launching will be implemented in Phase 15."
        }
    }
}
