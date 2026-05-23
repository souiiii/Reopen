import Foundation

struct AppSettings: Codable, Equatable, Sendable {
    var launchAtLogin: Bool
    var showDockIcon: Bool
    var askBeforeRunningTerminalCommands: Bool
    var defaultLaunchDelay: TimeInterval
    var enableWindowRestore: Bool
    var preferredTerminalApp: PreferredTerminalApp
    var preferredCodeEditor: PreferredCodeEditor

    init(
        launchAtLogin: Bool = false,
        showDockIcon: Bool = false,
        askBeforeRunningTerminalCommands: Bool = true,
        defaultLaunchDelay: TimeInterval = 0.05,
        enableWindowRestore: Bool = true,
        preferredTerminalApp: PreferredTerminalApp = .terminal,
        preferredCodeEditor: PreferredCodeEditor = .visualStudioCode
    ) {
        self.launchAtLogin = launchAtLogin
        self.showDockIcon = showDockIcon
        self.askBeforeRunningTerminalCommands = askBeforeRunningTerminalCommands
        self.defaultLaunchDelay = defaultLaunchDelay
        self.enableWindowRestore = enableWindowRestore
        self.preferredTerminalApp = preferredTerminalApp
        self.preferredCodeEditor = preferredCodeEditor
    }
}

final class SettingsRuntime: @unchecked Sendable {
    private let lock = NSLock()
    private var storedSettings: AppSettings

    init(settings: AppSettings = AppSettings()) {
        storedSettings = settings
    }

    var settings: AppSettings {
        lock.lock()
        defer { lock.unlock() }
        return storedSettings
    }

    func update(_ settings: AppSettings) {
        lock.lock()
        storedSettings = settings
        lock.unlock()
    }
}
