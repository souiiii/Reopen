import AppKit
import UniformTypeIdentifiers

enum AppPicker {
    @MainActor
    static func pickApplication() -> WorkspaceActionDraft? {
        let panel = NSOpenPanel()
        panel.title = "Add App"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.applicationBundle]
        panel.directoryURL = URL(fileURLWithPath: "/Applications", isDirectory: true)

        guard panel.runModal() == .OK, let url = panel.url else {
            return nil
        }

        return WorkspaceActionDraft.app(
            name: url.deletingPathExtension().lastPathComponent,
            path: url.path,
            bundleIdentifier: Bundle(url: url)?.bundleIdentifier
        )
    }
}
