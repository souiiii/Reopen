import AppKit
import SwiftUI

@MainActor
final class WorkspaceHubPanelController: NSObject, NSPopoverDelegate {
    private enum Metrics {
        static let contentSize = NSSize(width: 480, height: 620)
    }

    private let environment: AppEnvironment
    private let popover: NSPopover
    private let state: WorkspaceHubState
    private let windowManager: WindowManager

    init(environment: AppEnvironment) {
        self.environment = environment
        self.popover = NSPopover()
        self.state = WorkspaceHubState()
        self.windowManager = WindowManager()
        super.init()

        configurePopover()
    }

    var isShown: Bool {
        popover.isShown
    }

    func toggle(relativeTo button: NSStatusBarButton) {
        if popover.isShown {
            close()
        } else {
            show(relativeTo: button)
        }
    }

    func show(relativeTo button: NSStatusBarButton) {
        guard !popover.isShown else {
            return
        }

        popover.show(
            relativeTo: button.bounds,
            of: button,
            preferredEdge: .minY
        )
        popover.contentViewController?.view.window?.makeKey()
    }

    func showCreateComposer(relativeTo button: NSStatusBarButton) {
        if !popover.isShown {
            show(relativeTo: button)
        } else {
            popover.contentViewController?.view.window?.makeKey()
        }

        state.startCreating()
    }

    func close() {
        popover.performClose(nil)
    }

    func popoverDidClose(_ notification: Notification) {
        state.resetForPanelClose()
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = Metrics.contentSize
        popover.delegate = self
        popover.contentViewController = NSHostingController(
            rootView: WorkspaceHubPanelView(
                state: state,
                onLaunchWorkspace: { [weak self] workspaceID in
                    self?.launchWorkspace(id: workspaceID)
                },
                onSaveCreateWorkspace: { [weak self] in
                    self?.saveCreateWorkspace()
                },
                onSaveEditWorkspace: { [weak self] in
                    self?.saveEditWorkspace()
                },
                onCaptureEditWindowLayout: { [weak self] in
                    self?.captureEditWindowLayout()
                },
                onDeleteWorkspace: { [weak self] workspaceID in
                    self?.deleteWorkspace(id: workspaceID)
                },
                onDuplicateWorkspace: { [weak self] workspaceID in
                    self?.duplicateWorkspace(id: workspaceID)
                },
                onMoveWorkspace: { [weak self] workspaceID, offset in
                    self?.moveWorkspace(id: workspaceID, offset: offset)
                },
                onRepairLaunchIssue: { [weak self] workspaceID, actionResult in
                    self?.repairLaunchIssue(actionResult, workspaceID: workspaceID)
                },
                onOpenSettings: { [weak self] in
                    self?.openSettings()
                },
                onQuit: {
                    NSApp.terminate(nil)
                }
            )
                .environmentObject(environment.appState)
        )
    }

    private func launchWorkspace(id workspaceID: UUID) {
        guard let workspace = environment.workspaceManager.getWorkspace(id: workspaceID) else {
            return
        }

        state.selectWorkspace(workspaceID)
        state.setExpandedCard(workspaceID: workspaceID)
        state.updateLaunchProgress(WorkspaceLaunchProgressSnapshot(
            workspaceID: workspace.id,
            workspaceName: workspace.name,
            stage: .preparing,
            message: "Launching..."
        ))

        environment.workspaceRunner.launchWorkspaceActionsAsync(
            in: workspace,
            progressHandler: { [weak self] snapshot in
                Task { @MainActor in
                    self?.state.updateLaunchProgress(snapshot)
                }
            },
            completion: { [weak self] result in
                Task { @MainActor in
                    guard let self else {
                        return
                    }

                    self.state.finishLaunch(result)

                    if !result.hasFailures {
                        self.clearSuccessfulLaunchStatusLater(
                            workspaceID: result.workspaceID,
                            resultID: result.id
                        )
                    }
                }
            }
        )
    }

    private func saveCreateWorkspace() {
        WorkspaceHubCreateCoordinator.saveCreateDraft(
            state: state,
            workspaceManager: environment.workspaceManager
        )
    }

    private func saveEditWorkspace() {
        WorkspaceHubEditCoordinator.saveEditDraft(
            state: state,
            workspaceManager: environment.workspaceManager
        )
    }

    private func captureEditWindowLayout() {
        do {
            let layouts = try windowManager.captureCurrentLayout(
                matching: state.editDraft.layoutCaptureBundleIdentifiers
            )
            state.editDraft.windowLayouts = layouts
            state.setEditLayoutMessage("Saved windows: \(layouts.count)")
        } catch let error as WindowManagerError {
            state.setEditLayoutMessage(error.userFacingMessage)
        } catch {
            state.setEditLayoutMessage("Window layout could not be saved.")
        }
    }

    private func deleteWorkspace(id workspaceID: UUID) {
        WorkspaceHubManagementCoordinator.deleteWorkspace(
            id: workspaceID,
            state: state,
            workspaceManager: environment.workspaceManager
        )
    }

    private func duplicateWorkspace(id workspaceID: UUID) {
        WorkspaceHubManagementCoordinator.duplicateWorkspace(
            id: workspaceID,
            state: state,
            workspaceManager: environment.workspaceManager
        )
    }

    private func moveWorkspace(id workspaceID: UUID, offset: Int) {
        WorkspaceHubManagementCoordinator.moveWorkspace(
            id: workspaceID,
            offset: offset,
            state: state,
            workspaceManager: environment.workspaceManager
        )
    }

    private func clearSuccessfulLaunchStatusLater(workspaceID: UUID, resultID: UUID) {
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000)

            await MainActor.run {
                self?.state.clearSuccessfulLaunchStatus(
                    workspaceID: workspaceID,
                    resultID: resultID
                )
            }
        }
    }

    private func repairLaunchIssue(_ actionResult: ActionLaunchResult, workspaceID: UUID) {
        guard
            let actionID = actionResult.actionID,
            var workspace = environment.workspaceManager.getWorkspace(id: workspaceID)
        else {
            return
        }

        switch (actionResult.errorCode, actionResult.actionType) {
        case ("missing_file", _), ("permission_file_access_missing", WorkspaceActionType.openFile.rawValue):
            guard let repairedAction = FilePicker.pickFile()?.makeHubRepairAction(for: actionID) else {
                return
            }
            replaceAction(id: actionID, with: repairedAction, in: &workspace)
        case ("missing_folder", _), ("permission_file_access_missing", WorkspaceActionType.openFolder.rawValue):
            guard let repairedAction = FolderPicker.pickFolderAction()?.makeHubRepairAction(for: actionID) else {
                return
            }
            replaceAction(id: actionID, with: repairedAction, in: &workspace)
        default:
            return
        }

        do {
            _ = try environment.workspaceManager.updateWorkspace(workspace)
        } catch {
            NSSound.beep()
        }
    }

    private func replaceAction(id actionID: UUID, with replacement: WorkspaceAction, in workspace: inout Workspace) {
        guard let index = workspace.actions.firstIndex(where: { $0.id == actionID }) else {
            return
        }

        workspace.actions[index] = replacement
    }

    private func openSettings() {
        close()
        environment.windowPresenter.showSettings(
            settingsManager: environment.settingsManager,
            workspaceManager: environment.workspaceManager
        )
    }
}

private extension WorkspaceActionDraft {
    func makeHubRepairAction(for actionID: UUID) -> WorkspaceAction? {
        var draft = self
        draft.id = actionID
        return try? draft.makeWorkspaceAction()
    }
}
