import AppKit
import SwiftUI

@MainActor
final class ManageWorkspacesWindowController: NSWindowController, NSWindowDelegate {
    private let onClose: () -> Void
    private var didClose = false

    init(
        appState: AppState,
        workspaceManager: WorkspaceManager,
        onEdit: @escaping (Workspace) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.onClose = onClose

        let view = ManageWorkspacesView(
            appState: appState,
            workspaceManager: workspaceManager,
            onEdit: onEdit
        )

        let window = NSWindow(contentViewController: NSHostingController(rootView: view))
        window.title = "Manage Workspaces"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 620, height: 460))
        window.minSize = NSSize(width: 520, height: 360)
        window.center()

        super.init(window: window)

        window.delegate = self
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        guard !didClose else {
            return
        }

        didClose = true
        onClose()
    }
}
