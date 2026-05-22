import Foundation

final class WorkspacePermissionChecker {
    typealias CheckPermissions = (Workspace) -> [ActionLaunchResult]

    private let checkPermissions: CheckPermissions

    init(checkPermissions: @escaping CheckPermissions = { _ in [] }) {
        self.checkPermissions = checkPermissions
    }

    func check(_ workspace: Workspace) -> [ActionLaunchResult] {
        checkPermissions(workspace)
    }
}
