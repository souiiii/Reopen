import AppKit
import SwiftUI

@MainActor
final class WorkspaceEditorWindowController: NSWindowController, NSWindowDelegate {
    private let onClose: () -> Void
    private var didClose = false

    init(workspaceManager: WorkspaceManager, onClose: @escaping () -> Void) {
        self.onClose = onClose

        let closeBox = WorkspaceEditorCloseBox()
        let view = WorkspaceEditorView(
            onSave: { draft in
                _ = try workspaceManager.createWorkspace(try draft.makeWorkspace())
            },
            onCancel: {
                closeBox.close()
            }
        )

        let window = NSWindow(contentViewController: NSHostingController(rootView: view))
        window.title = "Create Workspace"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 720, height: 620))
        window.minSize = NSSize(width: 620, height: 520)
        window.center()

        super.init(window: window)

        window.delegate = self
        closeBox.closeHandler = { [weak self] in
            self?.close()
        }
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

private final class WorkspaceEditorCloseBox {
    var closeHandler: (() -> Void)?

    func close() {
        closeHandler?()
    }
}
