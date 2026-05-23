import Foundation

enum WorkspaceSummaryCheckFailure: Error, CustomStringConvertible {
    case message(String)

    var description: String {
        switch self {
        case .message(let message):
            return message
        }
    }
}

func check(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() {
        throw WorkspaceSummaryCheckFailure.message(message)
    }
}

@main
enum WorkspaceSummaryChecks {
    static func main() throws {
        try mixedWorkspaceSummary()
        try emptyWorkspaceSummary()
        try savedDescriptionIsPreserved()
        try disabledWindowRestoreIsSummarized()

        print("Workspace summary checks passed.")
    }

    private static func mixedWorkspaceSummary() throws {
        let workspace = Workspace(
            name: "Daily",
            actions: [
                .openApp(OpenAppAction(name: "Safari", path: "/Applications/Safari.app", bundleIdentifier: "com.apple.Safari")),
                .openApp(OpenAppAction(name: "Mail", path: "/Applications/Mail.app", bundleIdentifier: "com.apple.mail")),
                .openFile(OpenFileAction(name: "Brief", path: "/Users/me/brief.pdf")),
                .openFolder(OpenFolderAction(name: "Project", path: "/Users/me/Project")),
                .openURL(OpenURLAction(url: "https://example.com", displayTitle: nil)),
                .terminalCommand(TerminalCommandAction(name: "Server", command: "npm start", workingDirectory: "/Users/me/Project")),
                .openVSCodeProject(OpenVSCodeProjectAction(projectPath: "/Users/me/Project")),
                .shellScript(ShellScriptAction(name: "Bootstrap", scriptPath: "/Users/me/bootstrap.sh"))
            ],
            windowLayouts: [
                WindowLayout(appBundleIdentifier: "com.apple.Safari", x: 0, y: 0, width: 900, height: 700)
            ]
        )

        let summary = WorkspaceSummaryBuilder.summary(for: workspace)

        try check(summary.displayName == "Daily", "Summary should preserve the workspace display name.")
        try check(summary.counts.appCount == 2, "Summary should count app actions.")
        try check(summary.counts.fileCount == 1, "Summary should count file actions.")
        try check(summary.counts.folderCount == 1, "Summary should count folder actions.")
        try check(summary.counts.urlCount == 1, "Summary should count URL actions.")
        try check(summary.counts.terminalCommandCount == 1, "Summary should count terminal actions.")
        try check(summary.counts.vsCodeProjectCount == 1, "Summary should count VS Code project actions.")
        try check(summary.counts.shellScriptCount == 1, "Summary should count shell script actions.")
        try check(summary.counts.totalActionCount == 8, "Summary should expose the total action count.")
        try check(summary.windowLayoutCount == 1, "Summary should count saved window layouts.")
        try check(summary.isWindowRestoreEnabled, "Summary should preserve the workspace window restore setting.")
        try check(summary.generatedDescription.contains("2 apps"), "Generated description should include app count.")
        try check(summary.generatedDescription.contains("Terminal"), "Generated description should include terminal actions.")
        try check(summary.generatedDescription.contains("VS Code"), "Generated description should include VS Code projects.")
        try check(summary.generatedDescription.contains("Script"), "Generated description should include shell scripts.")
        try check(summary.generatedDescription.contains("Window restore"), "Generated description should include enabled window restore.")
        try check(summary.previewItems.count == 8, "Summary should include preview items for all actions.")
        try check(summary.previewItems.first?.appPath == "/Applications/Safari.app", "App preview should preserve the app path for later icon rendering.")
        try check(summary.chips.contains(where: { $0.title == "2 Apps" }), "Summary should include app chips.")
        try check(summary.chips.contains(where: { $0.id == "windowRestore" }), "Summary should include a window restore chip.")
    }

    private static func emptyWorkspaceSummary() throws {
        let summary = WorkspaceSummaryBuilder.summary(for: Workspace(name: "  "))

        try check(summary.displayName == "Workspace", "Blank workspace names should get a useful display fallback.")
        try check(summary.generatedDescription == "No actions yet", "Empty workspaces should show a useful generated state.")
        try check(summary.displayDescription == "No actions yet", "Empty workspaces should use the generated display description.")
        try check(summary.previewItems.isEmpty, "Empty workspaces should not have preview items.")
        try check(summary.chips.isEmpty, "Empty workspaces should not have chips.")
        try check(summary.isEmpty, "Empty workspaces should report empty summary state.")
    }

    private static func savedDescriptionIsPreserved() throws {
        let workspace = Workspace(
            name: "Research",
            description: "Open the research stack.",
            actions: [
                .openURL(OpenURLAction(url: "https://example.com"))
            ]
        )

        let summary = WorkspaceSummaryBuilder.summary(for: workspace)

        try check(summary.savedDescription == "Open the research stack.", "Summary should preserve saved descriptions.")
        try check(summary.generatedDescription == "1 link", "Summary should still generate an action description.")
        try check(summary.displayDescription == "Open the research stack.", "Display description should prefer the saved description.")
    }

    private static func disabledWindowRestoreIsSummarized() throws {
        let workspace = Workspace(
            name: "Layout",
            windowLayouts: [
                WindowLayout(appBundleIdentifier: "com.apple.Terminal", x: 0, y: 0, width: 800, height: 600)
            ],
            isWindowRestoreEnabled: false
        )

        let summary = WorkspaceSummaryBuilder.summary(for: workspace)

        try check(!summary.isWindowRestoreEnabled, "Summary should preserve disabled window restore.")
        try check(summary.generatedDescription == "Window restore off", "Disabled window restore should be visible when layouts exist.")
        try check(summary.chips.contains(where: { $0.title == "Windows off" }), "Disabled window restore should produce a calm chip.")
    }
}
