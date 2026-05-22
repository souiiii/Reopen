import AppKit

enum FolderPicker {
    @MainActor
    static func pickFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Choose Folder"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false

        guard panel.runModal() == .OK else {
            return nil
        }

        return panel.url
    }

    @MainActor
    static func pickFolderAction() -> WorkspaceActionDraft? {
        guard let url = pickFolder() else {
            return nil
        }

        return WorkspaceActionDraft.folder(name: url.lastPathComponent, path: url.path)
    }
}
