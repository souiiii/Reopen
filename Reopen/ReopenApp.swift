import SwiftUI

@main
struct ReopenApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsPlaceholderView()
        }
    }
}

private struct SettingsPlaceholderView: View {
    var body: some View {
        Text("Reopen settings are available from the menu bar item.")
            .frame(width: 360, height: 120)
            .padding()
    }
}
