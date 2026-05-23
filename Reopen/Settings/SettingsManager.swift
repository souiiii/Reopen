import AppKit
import Foundation
import ServiceManagement

enum SettingsManagerError: Error, Equatable {
    case importRequiresConfirmation
    case resetRequiresConfirmation

    var userFacingMessage: String {
        switch self {
        case .importRequiresConfirmation:
            return "Importing workspace data requires confirmation."
        case .resetRequiresConfirmation:
            return "Resetting app data requires confirmation."
        }
    }
}

@MainActor
protocol LaunchAtLoginManaging {
    func setLaunchAtLoginEnabled(_ enabled: Bool) throws
}

@MainActor
final class LaunchAtLoginService: LaunchAtLoginManaging {
    func setLaunchAtLoginEnabled(_ enabled: Bool) throws {
        if enabled {
            guard SMAppService.mainApp.status != .enabled else {
                return
            }

            try SMAppService.mainApp.register()
        } else {
            guard SMAppService.mainApp.status == .enabled else {
                return
            }

            try SMAppService.mainApp.unregister()
        }
    }
}

@MainActor
protocol DockIconManaging {
    func setDockIconVisible(_ visible: Bool)
}

@MainActor
final class DockIconService: DockIconManaging {
    func setDockIconVisible(_ visible: Bool) {
        NSApp.setActivationPolicy(visible ? .regular : .accessory)
    }
}

@MainActor
final class SettingsManager: ObservableObject {
    @Published private(set) var settings: AppSettings
    @Published var statusMessage: String?
    @Published var errorMessage: String?

    private let settingsStore: SettingsStore
    private let runtime: SettingsRuntime
    private let launchAtLoginService: any LaunchAtLoginManaging
    private let dockIconService: any DockIconManaging
    private let importExportManager: WorkspaceImportExportManager

    init(
        settings: AppSettings,
        settingsStore: SettingsStore,
        runtime: SettingsRuntime,
        launchAtLoginService: (any LaunchAtLoginManaging)? = nil,
        dockIconService: (any DockIconManaging)? = nil,
        importExportManager: WorkspaceImportExportManager = WorkspaceImportExportManager()
    ) {
        self.settings = settings
        self.settingsStore = settingsStore
        self.runtime = runtime
        self.launchAtLoginService = launchAtLoginService ?? LaunchAtLoginService()
        self.dockIconService = dockIconService ?? DockIconService()
        self.importExportManager = importExportManager
        self.runtime.update(settings)
    }

    func applyCurrentSettings() {
        do {
            try applyBehavior(settings, previousSettings: nil)
            runtime.update(settings)
        } catch {
            report(error)
        }
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        updateSettings("Launch at login updated.") { settings in
            settings.launchAtLogin = enabled
        }
    }

    func setShowDockIcon(_ visible: Bool) {
        updateSettings("Dock icon setting updated.") { settings in
            settings.showDockIcon = visible
        }
    }

    func setAskBeforeRunningTerminalCommands(_ enabled: Bool) {
        updateSettings("Terminal safety setting updated.") { settings in
            settings.askBeforeRunningTerminalCommands = enabled
        }
    }

    func setDefaultLaunchDelay(_ delay: TimeInterval) {
        updateSettings("Launch delay updated.") { settings in
            settings.defaultLaunchDelay = min(max(delay, 0), 5)
        }
    }

    func setEnableWindowRestore(_ enabled: Bool) {
        updateSettings("Window restore setting updated.") { settings in
            settings.enableWindowRestore = enabled
        }
    }

    func setPreferredTerminalApp(_ terminalApp: PreferredTerminalApp) {
        updateSettings("Preferred terminal updated.") { settings in
            settings.preferredTerminalApp = terminalApp
        }
    }

    func setPreferredCodeEditor(_ codeEditor: PreferredCodeEditor) {
        updateSettings("Preferred code editor updated.") { settings in
            settings.preferredCodeEditor = codeEditor
        }
    }

    func exportWorkspaces(from workspaceManager: WorkspaceManager, to url: URL) {
        do {
            try importExportManager.exportWorkspaces(workspaceManager.getAllWorkspaces(), to: url)
            clearError()
            statusMessage = "Exported workspace data."
        } catch {
            report(error)
        }
    }

    func importWorkspaces(
        from url: URL,
        into workspaceManager: WorkspaceManager,
        confirmed: Bool
    ) {
        do {
            guard confirmed else {
                throw SettingsManagerError.importRequiresConfirmation
            }

            let result = try importExportManager.importWorkspaces(from: url)
            try workspaceManager.replaceWorkspaces(result.workspaces, confirmed: true)
            clearError()
            statusMessage = "Imported \(result.importedCount) workspace\(result.importedCount == 1 ? "" : "s")."
        } catch {
            report(error)
        }
    }

    func resetAppData(workspaceManager: WorkspaceManager, confirmed: Bool) {
        do {
            guard confirmed else {
                throw SettingsManagerError.resetRequiresConfirmation
            }

            let defaults = AppSettings()
            try workspaceManager.replaceWorkspaces([], confirmed: true)
            try applyAndPersist(defaults, previousSettings: settings)
            publish(defaults)
            clearError()
            statusMessage = "App data reset."
        } catch {
            report(error)
        }
    }

    private func updateSettings(
        _ successMessage: String,
        mutate: (inout AppSettings) -> Void
    ) {
        var updatedSettings = settings
        mutate(&updatedSettings)

        do {
            try applyAndPersist(updatedSettings, previousSettings: settings)
            publish(updatedSettings)
            clearError()
            statusMessage = successMessage
        } catch {
            report(error)
        }
    }

    private func applyAndPersist(_ updatedSettings: AppSettings, previousSettings: AppSettings) throws {
        do {
            try applyBehavior(updatedSettings, previousSettings: previousSettings)
            try settingsStore.saveSettings(updatedSettings)
        } catch {
            try? applyBehavior(previousSettings, previousSettings: updatedSettings)
            throw error
        }
    }

    private func applyBehavior(_ updatedSettings: AppSettings, previousSettings: AppSettings?) throws {
        if previousSettings?.launchAtLogin != updatedSettings.launchAtLogin {
            try launchAtLoginService.setLaunchAtLoginEnabled(updatedSettings.launchAtLogin)
        }

        if previousSettings?.showDockIcon != updatedSettings.showDockIcon {
            dockIconService.setDockIconVisible(updatedSettings.showDockIcon)
        }
    }

    private func publish(_ updatedSettings: AppSettings) {
        settings = updatedSettings
        runtime.update(updatedSettings)
    }

    private func clearError() {
        errorMessage = nil
    }

    private func report(_ error: Error) {
        statusMessage = nil

        if let settingsError = error as? SettingsManagerError {
            errorMessage = settingsError.userFacingMessage
        } else if let importExportError = error as? WorkspaceImportExportError {
            errorMessage = importExportError.userFacingMessage
        } else if let storageError = error as? StorageError {
            errorMessage = storageError.userFacingMessage
        } else if let workspaceError = error as? WorkspaceManagerError {
            errorMessage = workspaceError.userFacingMessage
        } else {
            errorMessage = error.localizedDescription
        }
    }
}
