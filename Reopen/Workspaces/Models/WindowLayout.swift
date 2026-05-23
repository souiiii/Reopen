import Foundation

enum WindowPlacement: String, Codable, CaseIterable, Equatable, Sendable {
    case leftHalf
    case rightHalf
    case topHalf
    case bottomHalf
    case center
    case fullscreen
    case customRectangle

    var title: String {
        switch self {
        case .leftHalf:
            return "Left Half"
        case .rightHalf:
            return "Right Half"
        case .topHalf:
            return "Top Half"
        case .bottomHalf:
            return "Bottom Half"
        case .center:
            return "Center"
        case .fullscreen:
            return "Fullscreen"
        case .customRectangle:
            return "Custom Rectangle"
        }
    }
}

struct WindowLayout: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var appBundleIdentifier: String
    var windowTitle: String?
    var screenIdentifier: String?
    var placement: WindowPlacement
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    init(
        id: UUID = UUID(),
        appBundleIdentifier: String,
        windowTitle: String? = nil,
        screenIdentifier: String? = nil,
        placement: WindowPlacement = .customRectangle,
        x: Double,
        y: Double,
        width: Double,
        height: Double
    ) {
        self.id = id
        self.appBundleIdentifier = appBundleIdentifier
        self.windowTitle = windowTitle
        self.screenIdentifier = screenIdentifier
        self.placement = placement
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        appBundleIdentifier = try container.decode(String.self, forKey: .appBundleIdentifier)
        windowTitle = try container.decodeIfPresent(String.self, forKey: .windowTitle)
        screenIdentifier = try container.decodeIfPresent(String.self, forKey: .screenIdentifier)
        placement = try container.decodeIfPresent(WindowPlacement.self, forKey: .placement) ?? .customRectangle
        x = try container.decode(Double.self, forKey: .x)
        y = try container.decode(Double.self, forKey: .y)
        width = try container.decode(Double.self, forKey: .width)
        height = try container.decode(Double.self, forKey: .height)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case appBundleIdentifier
        case windowTitle
        case screenIdentifier
        case placement
        case x
        case y
        case width
        case height
    }
}
