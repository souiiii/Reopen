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
        environment.appState.onWorkspaceListChanged = { [weak self] in
            self?.rebuildMenu()
        }
        configureStatusButton()
        rebuildMenu()
    }

    func uninstall() {
        environment.appState.onWorkspaceListChanged = nil
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
            for workspace in environment.appState.workspaces {
                let item = NSMenuItem(title: workspace.name, action: #selector(launchWorkspace(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = workspace.id
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
        guard
            let workspaceID = sender.representedObject as? UUID,
            let workspace = environment.workspaceManager.getWorkspace(id: workspaceID)
        else {
            return
        }

        let initialProgress = WorkspaceLaunchProgressSnapshot(
            workspaceID: workspace.id,
            workspaceName: workspace.name,
            stage: .preparing,
            message: "Preparing launch..."
        )
        environment.windowPresenter.showLaunchProgress(initialProgress)

        environment.workspaceRunner.launchWorkspaceActionsAsync(
            in: workspace,
            progressHandler: { [weak self] snapshot in
                Task { @MainActor in
                    self?.environment.windowPresenter.updateLaunchProgress(snapshot)
                }
            },
            completion: { [weak self] result in
                Task { @MainActor in
                    guard let self else {
                        return
                    }

                    self.environment.windowPresenter.closeLaunchProgress(workspaceID: workspace.id)
                    self.environment.windowPresenter.showLaunchResult(
                        result,
                        workspaceManager: self.environment.workspaceManager,
                        permissionManager: self.environment.permissionManager
                    )
                }
            }
        )
    }

    @objc private func createWorkspace() {
        environment.windowPresenter.showWorkspaceCreation(
            workspaceManager: environment.workspaceManager,
            settings: environment.settingsManager.settings
        )
    }

    @objc private func manageWorkspaces() {
        environment.windowPresenter.showWorkspaceManagement(
            appState: environment.appState,
            workspaceManager: environment.workspaceManager,
            settings: environment.settingsManager.settings
        )
    }

    @objc private func openSettings() {
        environment.windowPresenter.showSettings(
            settingsManager: environment.settingsManager,
            workspaceManager: environment.workspaceManager
        )
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
