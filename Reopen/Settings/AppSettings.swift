import Foundation

struct AppSettings: Codable, Equatable, Sendable {
    var launchAtLogin: Bool
    var showDockIcon: Bool
    var askBeforeRunningTerminalCommands: Bool
    var defaultLaunchDelay: TimeInterval
    var enableWindowRestore: Bool
    var preferredTerminalApp: PreferredTerminalApp
    var preferredCodeEditor: PreferredCodeEditor
    var includeTerminalCommandOutputInLogs: Bool
    var hasCompletedOnboarding: Bool
    var licenseTier: LicenseTier

    init(
        launchAtLogin: Bool = false,
        showDockIcon: Bool = false,
        askBeforeRunningTerminalCommands: Bool = true,
        defaultLaunchDelay: TimeInterval = 0.05,
        enableWindowRestore: Bool = true,
        preferredTerminalApp: PreferredTerminalApp = .terminal,
        preferredCodeEditor: PreferredCodeEditor = .visualStudioCode,
        includeTerminalCommandOutputInLogs: Bool = false,
        hasCompletedOnboarding: Bool = false,
        licenseTier: LicenseTier = .paid
    ) {
        self.launchAtLogin = launchAtLogin
        self.showDockIcon = showDockIcon
        self.askBeforeRunningTerminalCommands = askBeforeRunningTerminalCommands
        self.defaultLaunchDelay = defaultLaunchDelay
        self.enableWindowRestore = enableWindowRestore
        self.preferredTerminalApp = preferredTerminalApp
        self.preferredCodeEditor = preferredCodeEditor
        self.includeTerminalCommandOutputInLogs = includeTerminalCommandOutputInLogs
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.licenseTier = licenseTier
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        showDockIcon = try container.decodeIfPresent(Bool.self, forKey: .showDockIcon) ?? false
        askBeforeRunningTerminalCommands = try container.decodeIfPresent(Bool.self, forKey: .askBeforeRunningTerminalCommands) ?? true
        defaultLaunchDelay = try container.decodeIfPresent(TimeInterval.self, forKey: .defaultLaunchDelay) ?? 0.05
        enableWindowRestore = try container.decodeIfPresent(Bool.self, forKey: .enableWindowRestore) ?? true
        preferredTerminalApp = try container.decodeIfPresent(PreferredTerminalApp.self, forKey: .preferredTerminalApp) ?? .terminal
        preferredCodeEditor = try container.decodeIfPresent(PreferredCodeEditor.self, forKey: .preferredCodeEditor) ?? .visualStudioCode
        includeTerminalCommandOutputInLogs = try container.decodeIfPresent(Bool.self, forKey: .includeTerminalCommandOutputInLogs) ?? false
        hasCompletedOnboarding = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding) ?? false
        licenseTier = try container.decodeIfPresent(LicenseTier.self, forKey: .licenseTier) ?? .paid
    }

    private enum CodingKeys: String, CodingKey {
        case launchAtLogin
        case showDockIcon
        case askBeforeRunningTerminalCommands
        case defaultLaunchDelay
        case enableWindowRestore
        case preferredTerminalApp
        case preferredCodeEditor
        case includeTerminalCommandOutputInLogs
        case hasCompletedOnboarding
        case licenseTier
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
