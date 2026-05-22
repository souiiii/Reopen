import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var workspaces: [Workspace] = []
    @Published var storageErrorMessage: String?

    var workspaceNames: [String] {
        workspaces.map(\.name)
    }

    func replaceWorkspaces(_ workspaces: [Workspace]) {
        self.workspaces = workspaces
    }
}
