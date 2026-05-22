import Foundation

struct WindowLayout: Identifiable, Codable, Equatable {
    let id: UUID
    var appBundleIdentifier: String
    var windowTitle: String?
    var screenIdentifier: String?
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    init(
        id: UUID = UUID(),
        appBundleIdentifier: String,
        windowTitle: String? = nil,
        screenIdentifier: String? = nil,
        x: Double,
        y: Double,
        width: Double,
        height: Double
    ) {
        self.id = id
        self.appBundleIdentifier = appBundleIdentifier
        self.windowTitle = windowTitle
        self.screenIdentifier = screenIdentifier
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}
