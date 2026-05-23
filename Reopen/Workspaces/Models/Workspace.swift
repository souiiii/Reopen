import Foundation

struct Workspace: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var name: String
    var icon: String?
    var color: String?
    var description: String?
    var actions: [WorkspaceAction]
    var windowLayouts: [WindowLayout]
    var isWindowRestoreEnabled: Bool
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
        isWindowRestoreEnabled: Bool = true,
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
        self.isWindowRestoreEnabled = isWindowRestoreEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decodeIfPresent(String.self, forKey: .icon)
        color = try container.decodeIfPresent(String.self, forKey: .color)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        actions = try container.decodeIfPresent([WorkspaceAction].self, forKey: .actions) ?? []
        windowLayouts = try container.decodeIfPresent([WindowLayout].self, forKey: .windowLayouts) ?? []
        isWindowRestoreEnabled = try container.decodeIfPresent(Bool.self, forKey: .isWindowRestoreEnabled) ?? true
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case icon
        case color
        case description
        case actions
        case windowLayouts
        case isWindowRestoreEnabled
        case createdAt
        case updatedAt
    }
}
