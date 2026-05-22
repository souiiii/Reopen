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
        menu.autoenablesItems = false

        let titleItem = NSMenuItem(title: MenuBarCommands.appTitle, action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(.separator())

        if let storageErrorMessage = environment.appState.storageErrorMessage {
            let storageErrorItem = NSMenuItem(title: storageErrorMessage, action: nil, keyEquivalent: "")
            storageErrorItem.isEnabled = false
            menu.addItem(storageErrorItem)
            menu.addItem(.separator())
        }

        let workspacesItem = NSMenuItem(title: MenuBarCommands.workspacesTitle, action: nil, keyEquivalent: "")
        workspacesItem.isEnabled = false
        menu.addItem(workspacesItem)

        if environment.appState.workspaceNames.isEmpty {
            let emptyItem = NSMenuItem(title: MenuBarCommands.noWorkspacesTitle, action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            for workspaceName in environment.appState.workspaceNames {
                let item = NSMenuItem(title: workspaceName, action: #selector(launchWorkspace(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = workspaceName
                item.isEnabled = true
                menu.addItem(item)
            }
        }

        menu.addItem(.separator())

        let createItem = NSMenuItem(title: MenuBarCommands.createWorkspaceTitle, action: #selector(createWorkspace), keyEquivalent: "n")
        createItem.target = self
        createItem.isEnabled = true
        menu.addItem(createItem)

        let manageItem = NSMenuItem(title: MenuBarCommands.manageWorkspacesTitle, action: #selector(manageWorkspaces), keyEquivalent: "")
        manageItem.target = self
        manageItem.isEnabled = true
        menu.addItem(manageItem)

        let settingsItem = NSMenuItem(title: MenuBarCommands.settingsTitle, action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        settingsItem.isEnabled = true
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: MenuBarCommands.quitTitle, action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        quitItem.isEnabled = true
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func launchWorkspace(_ sender: NSMenuItem) {
        guard let workspaceName = sender.representedObject as? String else {
            return
        }

        environment.windowPresenter.show(.launchWorkspace(workspaceName))
    }

    @objc private func createWorkspace() {
        environment.windowPresenter.show(.createWorkspace)
    }

    @objc private func manageWorkspaces() {
        environment.windowPresenter.show(.manageWorkspaces)
    }

    @objc private func openSettings() {
        environment.windowPresenter.show(.settings)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
