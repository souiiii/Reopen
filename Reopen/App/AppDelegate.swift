import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var environment: AppEnvironment?
    private var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let environment = AppEnvironment.bootstrap()
        let menuBarController = MenuBarController(environment: environment)
        menuBarController.install()
        environment.errorLogger.logAppStarted()

        if environment.appState.workspaces.isEmpty && !environment.settingsManager.settings.hasCompletedOnboarding {
            environment.windowPresenter.showOnboarding(
                workspaceManager: environment.workspaceManager,
                settingsManager: environment.settingsManager
            )
        }

        self.environment = environment
        self.menuBarController = menuBarController
    }

    func applicationWillTerminate(_ notification: Notification) {
        environment?.errorLogger.logAppWillTerminate()
        menuBarController?.uninstall()
    }
}
