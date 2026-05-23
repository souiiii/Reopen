import AppKit
import Foundation

final class PermissionManager: @unchecked Sendable {
    private let accessibilityPermissionService: AccessibilityPermissionService
    private let automationPermissionService: AutomationPermissionService
    private let fileAccessService: FileAccessService
    private let openURL: @Sendable (URL) -> Bool

    init(
        accessibilityPermissionService: AccessibilityPermissionService = AccessibilityPermissionService(),
        automationPermissionService: AutomationPermissionService = AutomationPermissionService(),
        fileAccessService: FileAccessService = FileAccessService(),
        openURL: @escaping @Sendable (URL) -> Bool = { url in
            NSWorkspace.shared.open(url)
        }
    ) {
        self.accessibilityPermissionService = accessibilityPermissionService
        self.automationPermissionService = automationPermissionService
        self.fileAccessService = fileAccessService
        self.openURL = openURL
    }

    func checkPermissions(for workspace: Workspace) -> WorkspacePermissionReport {
        var report = WorkspacePermissionReport()

        appendAccessibilityIssues(for: workspace, to: &report)
        appendAutomationIssues(for: workspace, to: &report)
        appendFileAccessIssues(for: workspace, to: &report)

        return report
    }

    func openSettings(for actionResult: ActionLaunchResult) -> Bool {
        guard let kind = PermissionKind.kind(for: actionResult.errorCode) else {
            return false
        }

        return openSettings(for: kind)
    }

    func openSettings(for kind: PermissionKind) -> Bool {
        guard let url = kind.settingsURL else {
            return false
        }

        return openURL(url)
    }

    func canOpenSettings(for actionResult: ActionLaunchResult) -> Bool {
        guard let kind = PermissionKind.kind(for: actionResult.errorCode) else {
            return false
        }

        return kind == .accessibility || kind == .automation
    }

    func canRepairFileAccess(for actionResult: ActionLaunchResult) -> Bool {
        actionResult.errorCode == "permission_file_access_missing"
    }

    private func appendAccessibilityIssues(for workspace: Workspace, to report: inout WorkspacePermissionReport) {
        guard workspace.isWindowRestoreEnabled, !workspace.windowLayouts.isEmpty else {
            return
        }

        guard !accessibilityPermissionService.status().isGranted else {
            return
        }

        for layout in workspace.windowLayouts {
            report.layoutResults.append(ActionLaunchResult(
                actionID: layout.id,
                actionType: "windowLayout",
                title: layout.windowTitle ?? "Window Layout",
                status: .skipped,
                message: PermissionKind.accessibility.explanation,
                errorCode: "permission_accessibility_missing"
            ))
            report.blockedLayoutIDs.insert(layout.id)
        }
    }

    private func appendAutomationIssues(for workspace: Workspace, to report: inout WorkspacePermissionReport) {
        let terminalActions = workspace.actions.compactMap { action -> TerminalCommandAction? in
            if case .terminalCommand(let payload) = action {
                return payload
            }

            return nil
        }

        guard !terminalActions.isEmpty else {
            return
        }

        let status = automationPermissionService.status(
            forBundleIdentifier: AutomationPermissionService.terminalBundleIdentifier
        )

        guard status == .denied else {
            return
        }

        for action in terminalActions {
            report.actionResults.append(ActionLaunchResult(
                actionID: action.id,
                actionType: WorkspaceActionType.terminalCommand.rawValue,
                title: action.name,
                status: .skipped,
                message: PermissionKind.automation.explanation,
                errorCode: "permission_automation_denied"
            ))
            report.blockedActionIDs.insert(action.id)
        }
    }

    private func appendFileAccessIssues(for workspace: Workspace, to report: inout WorkspacePermissionReport) {
        for action in workspace.actions {
            switch action {
            case .openFile(let payload) where fileAccessService.needsRenewedAccess(payload):
                report.actionResults.append(fileAccessResult(
                    actionID: payload.id,
                    actionType: WorkspaceActionType.openFile.rawValue,
                    title: payload.name
                ))
            case .openFolder(let payload) where fileAccessService.needsRenewedAccess(payload):
                report.actionResults.append(fileAccessResult(
                    actionID: payload.id,
                    actionType: WorkspaceActionType.openFolder.rawValue,
                    title: payload.name
                ))
            default:
                continue
            }
        }
    }

    private func fileAccessResult(actionID: UUID, actionType: String, title: String) -> ActionLaunchResult {
        ActionLaunchResult(
            actionID: actionID,
            actionType: actionType,
            title: title,
            status: .skipped,
            message: PermissionKind.fileAccess.explanation,
            errorCode: "permission_file_access_missing"
        )
    }
}
