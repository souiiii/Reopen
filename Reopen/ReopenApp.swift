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
        Text("Reopen settings are coming in a later phase.")
            .frame(width: 360, height: 120)
            .padding()
    }
}
