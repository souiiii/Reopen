import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    let workspaceManager: WorkspaceManager

    @State private var confirmation: SettingsConfirmation?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider()

            Form {
                appBehaviorSection
                launchSection
                defaultsSection
                privacySection
                licenseSection
                dataSection
                importSummarySection
            }
            .formStyle(.grouped)
            .padding(.top, 4)

            statusFooter
        }
        .frame(minWidth: 540, minHeight: 520)
        .alert(item: $confirmation, content: confirmationAlert)
    }

    private var header: some View {
        HStack {
            Label("Settings", systemImage: "gearshape")
                .font(.title3)
                .fontWeight(.semibold)

            Spacer()
        }
        .padding([.top, .horizontal], 20)
        .padding(.bottom, 14)
    }

    private var appBehaviorSection: some View {
        Section("App") {
            Toggle(
                "Launch Reopen at login",
                isOn: Binding(
                    get: { settingsManager.settings.launchAtLogin },
                    set: { value in settingsManager.setLaunchAtLogin(value) }
                )
            )

            Toggle(
                "Show Dock icon",
                isOn: Binding(
                    get: { settingsManager.settings.showDockIcon },
                    set: { value in settingsManager.setShowDockIcon(value) }
                )
            )
        }
    }

    private var launchSection: some View {
        Section("Launch") {
            Toggle(
                "Ask before running terminal commands",
                isOn: Binding(
                    get: { settingsManager.settings.askBeforeRunningTerminalCommands },
                    set: { value in settingsManager.setAskBeforeRunningTerminalCommands(value) }
                )
            )

            HStack {
                Text("Default launch delay")

                Spacer()

                Stepper(
                    launchDelayText,
                    value: Binding(
                        get: { settingsManager.settings.defaultLaunchDelay },
                        set: { value in settingsManager.setDefaultLaunchDelay(value) }
                    ),
                    in: 0...5,
                    step: 0.05
                )
            }

            Toggle(
                "Enable window restore",
                isOn: Binding(
                    get: { settingsManager.settings.enableWindowRestore },
                    set: { value in settingsManager.setEnableWindowRestore(value) }
                )
            )
        }
    }

    private var defaultsSection: some View {
        Section("Defaults") {
            Picker(
                "Preferred terminal app",
                selection: Binding(
                    get: { settingsManager.settings.preferredTerminalApp.rawValue },
                    set: { rawValue in
                        guard let terminalApp = PreferredTerminalApp(rawValue: rawValue) else {
                            return
                        }

                        settingsManager.setPreferredTerminalApp(terminalApp)
                    }
                )
            ) {
                ForEach(PreferredTerminalApp.allCases, id: \.rawValue) { terminalApp in
                    Text(terminalApp.displayName).tag(terminalApp.rawValue)
                }
            }

            Picker(
                "Preferred code editor",
                selection: Binding(
                    get: { settingsManager.settings.preferredCodeEditor.rawValue },
                    set: { rawValue in
                        guard let codeEditor = PreferredCodeEditor(rawValue: rawValue) else {
                            return
                        }

                        settingsManager.setPreferredCodeEditor(codeEditor)
                    }
                )
            ) {
                ForEach(PreferredCodeEditor.allCases, id: \.rawValue) { codeEditor in
                    Text(codeEditor.displayName).tag(codeEditor.rawValue)
                }
            }
        }
    }

    private var privacySection: some View {
        Section("Privacy") {
            Toggle(
                "Include terminal command output in logs",
                isOn: Binding(
                    get: { settingsManager.settings.includeTerminalCommandOutputInLogs },
                    set: { value in settingsManager.setIncludeTerminalCommandOutputInLogs(value) }
                )
            )
            Text("Reopen does not log terminal command output unless this is enabled.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var licenseSection: some View {
        Section("License") {
            Picker(
                "Plan",
                selection: Binding(
                    get: { settingsManager.settings.licenseTier.rawValue },
                    set: { rawValue in
                        guard let tier = LicenseTier(rawValue: rawValue) else {
                            return
                        }

                        settingsManager.setLicenseTier(tier)
                    }
                )
            ) {
                ForEach(LicenseTier.allCases, id: \.rawValue) { tier in
                    Text(tier.title).tag(tier.rawValue)
                }
            }

            Text(LicenseManager().planSummary(for: settingsManager.settings.licenseTier))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var dataSection: some View {
        Section("Data") {
            HStack(spacing: 10) {
                Button(action: exportWorkspaces) {
                    Label("Export Workspaces", systemImage: "square.and.arrow.up")
                }

                Button(action: chooseImportFile) {
                    Label("Import Workspaces", systemImage: "square.and.arrow.down")
                }

                Spacer()

                Button(role: .destructive) {
                    confirmation = .reset
                } label: {
                    Label("Reset App Data", systemImage: "trash")
                }
            }
        }
    }

    @ViewBuilder
    private var importSummarySection: some View {
        if let summary = settingsManager.lastImportSummary {
            Section("Import Summary") {
                if summary.importedWorkspaces.isEmpty {
                    Text("No workspaces were added.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(summary.importedWorkspaces) { workspace in
                        HStack {
                            Image(systemName: workspace.didRegenerateID ? "arrow.triangle.2.circlepath" : "checkmark.circle")
                                .foregroundStyle(workspace.didRegenerateID ? .orange : .green)

                            Text(workspace.name)

                            Spacer()

                            if workspace.didRegenerateID {
                                Text("New ID")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var statusFooter: some View {
        if let errorMessage = settingsManager.errorMessage {
            Text(errorMessage)
                .font(.footnote)
                .foregroundStyle(.red)
                .padding([.horizontal, .bottom], 20)
        } else if let statusMessage = settingsManager.statusMessage {
            Text(statusMessage)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding([.horizontal, .bottom], 20)
        }
    }

    private var launchDelayText: String {
        "\(settingsManager.settings.defaultLaunchDelay.formatted(.number.precision(.fractionLength(2))))s"
    }

    private func exportWorkspaces() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = "Reopen Workspaces.json"
        panel.title = "Export Workspaces"

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        settingsManager.exportWorkspaces(from: workspaceManager, to: url)
    }

    private func chooseImportFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.title = "Import Workspaces"

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        confirmation = .importWorkspaces(url)
    }

    private func confirmationAlert(_ confirmation: SettingsConfirmation) -> Alert {
        switch confirmation {
        case .importWorkspaces(let url):
            return Alert(
                title: Text("Import Workspaces?"),
                message: Text("Workspaces from the selected file will be added. Duplicate IDs will be regenerated."),
                primaryButton: .default(Text("Import")) {
                    settingsManager.importWorkspaces(
                        from: url,
                        into: workspaceManager,
                        confirmed: true
                    )
                },
                secondaryButton: .cancel()
            )
        case .reset:
            return Alert(
                title: Text("Reset App Data?"),
                message: Text("All workspaces and settings will be reset."),
                primaryButton: .destructive(Text("Reset")) {
                    settingsManager.resetAppData(
                        workspaceManager: workspaceManager,
                        confirmed: true
                    )
                },
                secondaryButton: .cancel()
            )
        }
    }
}

private enum SettingsConfirmation: Identifiable {
    case importWorkspaces(URL)
    case reset

    var id: String {
        switch self {
        case .importWorkspaces(let url):
            return "import-\(url.path)"
        case .reset:
            return "reset"
        }
    }
}
