import AppKit
import SwiftUI

@MainActor
final class LaunchResultWindowController: NSWindowController, NSWindowDelegate {
    private let onClose: () -> Void
    private var didClose = false

    init(result: WorkspaceLaunchResult, onClose: @escaping () -> Void) {
        self.onClose = onClose

        let window = NSWindow(contentViewController: NSHostingController(rootView: LaunchResultView(result: result)))
        window.title = "\(result.workspaceName) Launch Result"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 520, height: 360))
        window.minSize = NSSize(width: 460, height: 280)
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
