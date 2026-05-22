import Foundation

struct Workspace: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var name: String
    var icon: String?
    var color: String?
    var description: String?
    var actions: [WorkspaceAction]
    var windowLayouts: [WindowLayout]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        icon: String? = nil,
        color: String? = nil,
        description: String? = nil,
        actions: [WorkspaceAction] = [],
        windowLayouts: [WindowLayout] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.description = description
        self.actions = actions
        self.windowLayouts = windowLayouts
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
