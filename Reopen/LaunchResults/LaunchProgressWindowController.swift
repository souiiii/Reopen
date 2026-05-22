import AppKit
import SwiftUI

@MainActor
final class LaunchProgressWindowController: NSWindowController, NSWindowDelegate {
    private let state: LaunchProgressState
    private let onClose: () -> Void
    private var didClose = false

    init(snapshot: WorkspaceLaunchProgressSnapshot, onClose: @escaping () -> Void) {
        self.state = LaunchProgressState(snapshot: snapshot)
        self.onClose = onClose

        let window = NSWindow(contentViewController: NSHostingController(rootView: LaunchProgressView(state: state)))
        window.title = "\(snapshot.workspaceName) Launch Progress"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 520, height: 320))
        window.minSize = NSSize(width: 460, height: 260)
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

    func update(snapshot: WorkspaceLaunchProgressSnapshot) {
        state.snapshot = snapshot
    }

    func windowWillClose(_ notification: Notification) {
        guard !didClose else {
            return
        }

        didClose = true
        onClose()
    }
}
