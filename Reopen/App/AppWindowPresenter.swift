import AppKit
import SwiftUI

@MainActor
final class AppWindowPresenter {
    private var windowControllers: [AppRoute: NSWindowController] = [:]

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
