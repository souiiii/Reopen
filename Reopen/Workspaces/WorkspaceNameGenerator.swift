import Foundation

enum WorkspaceNameGenerator {
    static let baseName = "Workspace"

    static func nextName(existingWorkspaces: [Workspace]) -> String {
        let existingNames = Set(existingWorkspaces.map { normalized($0.name) })
        var index = 1

        while existingNames.contains("\(baseName) \(index)") {
            index += 1
        }

        return "\(baseName) \(index)"
    }

    private static func normalized(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
