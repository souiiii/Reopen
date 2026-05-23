import AppKit
import SwiftUI

@MainActor
final class AppWindowPresenter {
    private var windowControllers: [AppRoute: NSWindowController] = [:]
    private var workspaceCreationController: WorkspaceEditorWindowController?
    private var workspaceEditingControllers: [UUID: WorkspaceEditorWindowController] = [:]
    private var workspaceManagementController: ManageWorkspacesWindowController?
    private var settingsController: SettingsWindowController?
    private var launchProgressControllers: [UUID: LaunchProgressWindowController] = [:]
    private var launchResultControllers: [UUID: LaunchResultWindowController] = [:]

    func showWorkspaceCreation(workspaceManager: WorkspaceManager, settings: AppSettings = AppSettings()) {
        if let existingController = workspaceCreationController {
            existingController.showWindow(nil)
            return
        }

        let controller = WorkspaceEditorWindowController(
            mode: .create,
            workspaceManager: workspaceManager,
            settings: settings,
            onClose: { [weak self] in
                self?.workspaceCreationController = nil
            }
        )
        workspaceCreationController = controller
        controller.showWindow(nil)
    }

    func showWorkspaceEditing(
        workspace: Workspace,
        workspaceManager: WorkspaceManager,
        settings: AppSettings = AppSettings()
    ) {
        if let existingController = workspaceEditingControllers[workspace.id] {
            existingController.showWindow(nil)
            return
        }

        let controller = WorkspaceEditorWindowController(
            mode: .edit(workspace),
            workspaceManager: workspaceManager,
            settings: settings,
            onClose: { [weak self] in
                self?.workspaceEditingControllers[workspace.id] = nil
            }
        )
        workspaceEditingControllers[workspace.id] = controller
        controller.showWindow(nil)
    }

    func showWorkspaceManagement(
        appState: AppState,
        workspaceManager: WorkspaceManager,
        settings: AppSettings = AppSettings()
    ) {
        if let existingController = workspaceManagementController {
            existingController.showWindow(nil)
            return
        }

        let controller = ManageWorkspacesWindowController(
            appState: appState,
            workspaceManager: workspaceManager,
            onEdit: { [weak self] workspace in
                self?.showWorkspaceEditing(
                    workspace: workspace,
                    workspaceManager: workspaceManager,
                    settings: settings
                )
            },
            onClose: { [weak self] in
                self?.workspaceManagementController = nil
            }
        )
        workspaceManagementController = controller
        controller.showWindow(nil)
    }

    func showSettings(settingsManager: SettingsManager, workspaceManager: WorkspaceManager) {
        if let existingController = settingsController {
            existingController.showWindow(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let controller = SettingsWindowController(
            settingsManager: settingsManager,
            workspaceManager: workspaceManager,
            onClose: { [weak self] in
                self?.settingsController = nil
            }
        )
        settingsController = controller
        controller.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showLaunchResult(
        _ result: WorkspaceLaunchResult,
        workspaceManager: WorkspaceManager,
        permissionManager: PermissionManager
    ) {
        let controller = LaunchResultWindowController(
            result: result,
            onRepair: { [weak self] actionResult in
                self?.repairMissingResource(
                    actionResult: actionResult,
                    workspaceID: result.workspaceID,
                    workspaceManager: workspaceManager
                )
            },
            onOpenPermissionSettings: { kind in
                _ = permissionManager.openSettings(for: kind)
            },
            onClose: { [weak self] in
                self?.launchResultControllers[result.id] = nil
            }
        )
        launchResultControllers[result.id] = controller
        controller.showWindow(nil)
    }

    func showLaunchProgress(_ snapshot: WorkspaceLaunchProgressSnapshot) {
        if let existingController = launchProgressControllers[snapshot.workspaceID] {
            existingController.update(snapshot: snapshot)
            existingController.showWindow(nil)
            return
        }

        let controller = LaunchProgressWindowController(
            snapshot: snapshot,
            onClose: { [weak self] in
                self?.launchProgressControllers[snapshot.workspaceID] = nil
            }
        )
        launchProgressControllers[snapshot.workspaceID] = controller
        controller.showWindow(nil)
    }

    func updateLaunchProgress(_ snapshot: WorkspaceLaunchProgressSnapshot) {
        if let existingController = launchProgressControllers[snapshot.workspaceID] {
            existingController.update(snapshot: snapshot)
        } else {
            showLaunchProgress(snapshot)
        }
    }

    func closeLaunchProgress(workspaceID: UUID) {
        let controller = launchProgressControllers[workspaceID]
        launchProgressControllers[workspaceID] = nil
        controller?.close()
    }

    func show(_ route: AppRoute) {
        if let existingController = windowControllers[route] {
            existingController.showWindow(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hostingController = NSHostingController(rootView: PlaceholderRouteView(route: route))
        let window = NSWindow(contentViewController: hostingController)
        window.title = route.title
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 420, height: 180))
        window.center()

        let controller = NSWindowController(window: window)
        windowControllers[route] = controller
        controller.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func repairMissingResource(
        actionResult: ActionLaunchResult,
        workspaceID: UUID,
        workspaceManager: WorkspaceManager
    ) {
        guard
            let actionID = actionResult.actionID,
            var workspace = workspaceManager.getWorkspace(id: workspaceID)
        else {
            return
        }

        switch (actionResult.errorCode, actionResult.actionType) {
        case ("missing_file", _), ("permission_file_access_missing", WorkspaceActionType.openFile.rawValue):
            guard let repairedAction = FilePicker.pickFile()?.makeRepairAction(for: actionID) else {
                return
            }
            replaceAction(id: actionID, with: repairedAction, in: &workspace)
        case ("missing_folder", _), ("permission_file_access_missing", WorkspaceActionType.openFolder.rawValue):
            guard let repairedAction = FolderPicker.pickFolderAction()?.makeRepairAction(for: actionID) else {
                return
            }
            replaceAction(id: actionID, with: repairedAction, in: &workspace)
        default:
            return
        }

        do {
            _ = try workspaceManager.updateWorkspace(workspace)
        } catch {
            NSSound.beep()
        }
    }

    private func replaceAction(id: UUID, with replacement: WorkspaceAction, in workspace: inout Workspace) {
        guard let index = workspace.actions.firstIndex(where: { $0.id == id }) else {
            return
        }

        workspace.actions[index] = replacement
    }
}

private struct PlaceholderRouteView: View {
    let route: AppRoute

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(route.title)
                .font(.title3)
                .fontWeight(.semibold)

            Text(route.placeholderMessage)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
    }
}

private extension WorkspaceActionDraft {
    func makeRepairAction(for actionID: UUID) -> WorkspaceAction? {
        var draft = self
        draft.id = actionID
        return try? draft.makeWorkspaceAction()
    }
}
