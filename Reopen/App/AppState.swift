import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var workspaceNames: [String] = []
}
