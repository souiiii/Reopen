import AppKit

@MainActor
final class MenuBarController: NSObject {
    private let environment: AppEnvironment
    private let statusItem: NSStatusItem

    init(environment: AppEnvironment) {
        self.environment = environment
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
    }

    func install() {
        configureStatusButton()
        rebuildMenu()
    }

    func uninstall() {
        NSStatusBar.system.removeStatusItem(statusItem)
    }

    private func configureStatusButton() {
        guard let button = statusItem.button else {
            return
        }

        button.toolTip = MenuBarCommands.appTitle

        if let image = NSImage(systemSymbolName: "arrow.clockwise.circle", accessibilityDescription: MenuBarCommands.appTitle) {
            image.isTemplate = true
            button.image = image
        } else {
            button.title = "Reopen"
        }
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        let titleItem = NSMenuItem(title: MenuBarCommands.appTitle, action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(.separator())

        if environment.appState.workspaceNames.isEmpty {
            let emptyItem = NSMenuItem(title: MenuBarCommands.noWorkspacesTitle, action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            for workspaceName in environment.appState.workspaceNames {
                let item = NSMenuItem(title: workspaceName, action: nil, keyEquivalent: "")
                item.isEnabled = false
                menu.addItem(item)
            }
        }

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: MenuBarCommands.quitTitle, action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
