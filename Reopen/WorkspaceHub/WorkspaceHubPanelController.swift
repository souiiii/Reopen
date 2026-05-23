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

    init(environment: AppEnvironment) {
        self.environment = environment
        self.popover = NSPopover()
        self.state = WorkspaceHubState()
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
                    self?.state.finishLaunch(result)
                }
            }
        )
    }

    private func openSettings() {
        close()
        environment.windowPresenter.showSettings(
            settingsManager: environment.settingsManager,
            workspaceManager: environment.workspaceManager
        )
    }
}
