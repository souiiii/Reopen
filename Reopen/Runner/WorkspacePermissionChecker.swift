import Foundation

struct WorkspacePermissionReport: Equatable, Sendable {
    var actionResults: [ActionLaunchResult]
    var layoutResults: [ActionLaunchResult]
    var blockedActionIDs: Set<UUID>
    var blockedLayoutIDs: Set<UUID>

    init(
        actionResults: [ActionLaunchResult] = [],
        layoutResults: [ActionLaunchResult] = [],
        blockedActionIDs: Set<UUID> = [],
        blockedLayoutIDs: Set<UUID> = []
    ) {
        self.actionResults = actionResults
        self.layoutResults = layoutResults
        self.blockedActionIDs = blockedActionIDs
        self.blockedLayoutIDs = blockedLayoutIDs
    }

    static let empty = WorkspacePermissionReport()
}

final class WorkspacePermissionChecker {
    typealias CheckPermissions = @Sendable (Workspace) -> WorkspacePermissionReport

    private let checkPermissions: CheckPermissions

    init(checkPermissions: @escaping CheckPermissions = { _ in .empty }) {
        self.checkPermissions = checkPermissions
    }

    func check(_ workspace: Workspace) -> WorkspacePermissionReport {
        checkPermissions(workspace)
    }
}
