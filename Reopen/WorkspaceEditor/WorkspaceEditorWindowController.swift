import AppKit
import SwiftUI

@MainActor
final class WorkspaceEditorWindowController: NSWindowController, NSWindowDelegate {
    private let onClose: () -> Void
    private var didClose = false

    init(
        mode: WorkspaceEditorMode,
        workspaceManager: WorkspaceManager,
        settings: AppSettings = AppSettings(),
        onClose: @escaping () -> Void
    ) {
        self.onClose = onClose

        let closeBox = WorkspaceEditorCloseBox()
        let view = WorkspaceEditorView(
            title: mode.title,
            saveButtonTitle: mode.saveButtonTitle,
            draft: mode.draft(settings: settings),
            settings: settings,
            onSave: { draft in
                let workspace = try draft.makeWorkspace()
                switch mode {
                case .create:
                    _ = try workspaceManager.createWorkspace(workspace)
                case .edit:
                    _ = try workspaceManager.updateWorkspace(workspace)
                }
            },
            onCancel: {
                closeBox.close()
            }
        )

        let window = NSWindow(contentViewController: NSHostingController(rootView: view))
        window.title = mode.title
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

enum WorkspaceEditorMode {
    case create
    case edit(Workspace)

    var title: String {
        switch self {
        case .create:
            return "Create Workspace"
        case .edit(let workspace):
            return "Edit \(workspace.name)"
        }
    }

    var saveButtonTitle: String {
        switch self {
        case .create:
            return "Save Workspace"
        case .edit:
            return "Save Changes"
        }
    }

    func draft(settings: AppSettings = AppSettings()) -> WorkspaceCreationDraft {
        switch self {
        case .create:
            var draft = WorkspaceCreationDraft()
            draft.isWindowRestoreEnabled = settings.enableWindowRestore
            return draft
        case .edit(let workspace):
            return WorkspaceCreationDraft(workspace: workspace)
        }
    }
}

private final class WorkspaceEditorCloseBox {
    var closeHandler: (() -> Void)?

    func close() {
        closeHandler?()
    }
}
