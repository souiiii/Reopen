import AppKit

enum FilePicker {
    @MainActor
    static func pickFile() -> WorkspaceActionDraft? {
        let panel = NSOpenPanel()
        panel.title = "Add File"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        guard panel.runModal() == .OK, let url = panel.url else {
            return nil
        }

        return WorkspaceActionDraft.file(
            name: url.lastPathComponent,
            path: url.path,
            securityScopedBookmarkData: SecurityScopedBookmark.makeBookmarkData(for: url)
        )
    }
}
