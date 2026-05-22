import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var environment: AppEnvironment?
    private var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let environment = AppEnvironment.bootstrap()
        let menuBarController = MenuBarController(environment: environment)
        menuBarController.install()

        self.environment = environment
        self.menuBarController = menuBarController
    }

    func applicationWillTerminate(_ notification: Notification) {
        menuBarController?.uninstall()
    }
}
