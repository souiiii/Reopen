import AppKit
import SwiftUI

@MainActor
final class OnboardingWindowController: NSWindowController, NSWindowDelegate {
    private let onClose: () -> Void
    private var didClose = false

    init(
        onCreateWorkspace: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void,
        onDone: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.onClose = onClose

        final class CloseBox {
            var close: (() -> Void)?
        }

        let closeBox = CloseBox()
        let view = OnboardingView(
            onCreateWorkspace: onCreateWorkspace,
            onOpenSettings: onOpenSettings,
            onDone: {
                onDone()
                closeBox.close?()
            }
        )
        let window = NSWindow(contentViewController: NSHostingController(rootView: view))
        window.title = "Welcome to Reopen"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 560, height: 320))
        window.center()

        super.init(window: window)
        window.delegate = self
        closeBox.close = { [weak self] in
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
