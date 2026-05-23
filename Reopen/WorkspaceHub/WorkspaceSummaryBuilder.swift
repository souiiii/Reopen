import Foundation

struct WorkspaceSummary: Equatable, Sendable {
    var workspaceID: UUID
    var displayName: String
    var savedDescription: String?
    var generatedDescription: String
    var displayDescription: String
    var workspaceIconSystemName: String?
    var primarySystemImageName: String
    var counts: WorkspaceSummaryCounts
    var isWindowRestoreEnabled: Bool
    var windowLayoutCount: Int
    var previewItems: [WorkspaceSummaryPreviewItem]
    var chips: [WorkspaceSummaryChip]

    var isEmpty: Bool {
        counts.totalActionCount == 0 && windowLayoutCount == 0
    }
}

struct WorkspaceSummaryCounts: Equatable, Sendable {
    var appCount = 0
    var fileCount = 0
    var folderCount = 0
    var urlCount = 0
    var terminalCommandCount = 0
    var vsCodeProjectCount = 0
    var shellScriptCount = 0

    var totalActionCount: Int {
        appCount
            + fileCount
            + folderCount
            + urlCount
            + terminalCommandCount
            + vsCodeProjectCount
            + shellScriptCount
    }
}

struct WorkspaceSummaryPreviewItem: Identifiable, Equatable, Sendable {
    var id: UUID
    var title: String
    var systemImageName: String
    var actionType: WorkspaceActionType
    var appPath: String?
    var bundleIdentifier: String?
}

struct WorkspaceSummaryChip: Identifiable, Equatable, Sendable {
    var id: String
    var title: String
    var systemImageName: String
    var isEmphasized: Bool
}

enum WorkspaceSummaryBuilder {
    static func summary(for workspace: Workspace) -> WorkspaceSummary {
        var counts = WorkspaceSummaryCounts()
        var previewItems: [WorkspaceSummaryPreviewItem] = []

        for action in workspace.actions {
            switch action {
            case .openApp(let payload):
                counts.appCount += 1
                previewItems.append(WorkspaceSummaryPreviewItem(
                    id: payload.id,
                    title: displayTitle(payload.name, fallbackPath: payload.path, fallback: "App"),
                    systemImageName: "app",
                    actionType: .openApp,
                    appPath: payload.path,
                    bundleIdentifier: payload.bundleIdentifier
                ))
            case .openFile(let payload):
                counts.fileCount += 1
                previewItems.append(WorkspaceSummaryPreviewItem(
                    id: payload.id,
                    title: displayTitle(payload.name, fallbackPath: payload.path, fallback: "File"),
                    systemImageName: "doc",
                    actionType: .openFile
                ))
            case .openFolder(let payload):
                counts.folderCount += 1
                previewItems.append(WorkspaceSummaryPreviewItem(
                    id: payload.id,
                    title: displayTitle(payload.name, fallbackPath: payload.path, fallback: "Folder"),
                    systemImageName: "folder",
                    actionType: .openFolder
                ))
            case .openURL(let payload):
                counts.urlCount += 1
                previewItems.append(WorkspaceSummaryPreviewItem(
                    id: payload.id,
                    title: displayTitle(payload.displayTitle, fallbackURL: payload.url, fallback: "Link"),
                    systemImageName: "link",
                    actionType: .openURL
                ))
            case .terminalCommand(let payload):
                counts.terminalCommandCount += 1
                previewItems.append(WorkspaceSummaryPreviewItem(
                    id: payload.id,
                    title: displayTitle(payload.name, fallback: "Terminal"),
                    systemImageName: "terminal",
                    actionType: .terminalCommand
                ))
            case .openVSCodeProject(let payload):
                counts.vsCodeProjectCount += 1
                previewItems.append(WorkspaceSummaryPreviewItem(
                    id: payload.id,
                    title: displayTitle(nil, fallbackPath: payload.projectPath, fallback: "VS Code"),
                    systemImageName: "chevron.left.forwardslash.chevron.right",
                    actionType: .openVSCodeProject
                ))
            case .shellScript(let payload):
                counts.shellScriptCount += 1
                previewItems.append(WorkspaceSummaryPreviewItem(
                    id: payload.id,
                    title: displayTitle(payload.name, fallbackPath: payload.scriptPath, fallback: "Script"),
                    systemImageName: "applescript",
                    actionType: .shellScript
                ))
            }
        }

        let savedDescription = optionalTrimmed(workspace.description)
        let generatedDescription = generatedDescription(
            counts: counts,
            isWindowRestoreEnabled: workspace.isWindowRestoreEnabled,
            windowLayoutCount: workspace.windowLayouts.count
        )
        let workspaceIconSystemName = optionalTrimmed(workspace.icon)
        let primarySystemImageName = workspaceIconSystemName
            ?? previewItems.first?.systemImageName
            ?? "square.grid.2x2"

        return WorkspaceSummary(
            workspaceID: workspace.id,
            displayName: displayTitle(workspace.name, fallback: "Workspace"),
            savedDescription: savedDescription,
            generatedDescription: generatedDescription,
            displayDescription: savedDescription ?? generatedDescription,
            workspaceIconSystemName: workspaceIconSystemName,
            primarySystemImageName: primarySystemImageName,
            counts: counts,
            isWindowRestoreEnabled: workspace.isWindowRestoreEnabled,
            windowLayoutCount: workspace.windowLayouts.count,
            previewItems: previewItems,
            chips: chips(
                counts: counts,
                isWindowRestoreEnabled: workspace.isWindowRestoreEnabled,
                windowLayoutCount: workspace.windowLayouts.count
            )
        )
    }

    private static func generatedDescription(
        counts: WorkspaceSummaryCounts,
        isWindowRestoreEnabled: Bool,
        windowLayoutCount: Int
    ) -> String {
        var parts: [String] = []

        appendCount(counts.appCount, singular: "app", plural: "apps", to: &parts)
        appendCount(counts.fileCount, singular: "file", plural: "files", to: &parts)
        appendCount(counts.folderCount, singular: "folder", plural: "folders", to: &parts)
        appendCount(counts.urlCount, singular: "link", plural: "links", to: &parts)
        appendNamedCount(counts.terminalCommandCount, singleTitle: "Terminal", pluralTitle: "terminal commands", to: &parts)
        appendNamedCount(counts.vsCodeProjectCount, singleTitle: "VS Code", pluralTitle: "VS Code projects", to: &parts)
        appendNamedCount(counts.shellScriptCount, singleTitle: "Script", pluralTitle: "scripts", to: &parts)

        if windowLayoutCount > 0 {
            parts.append(isWindowRestoreEnabled ? "Window restore" : "Window restore off")
        }

        return parts.isEmpty ? "No actions yet" : parts.joined(separator: " · ")
    }

    private static func chips(
        counts: WorkspaceSummaryCounts,
        isWindowRestoreEnabled: Bool,
        windowLayoutCount: Int
    ) -> [WorkspaceSummaryChip] {
        var chips: [WorkspaceSummaryChip] = []

        appendChip(counts.appCount, singular: "App", plural: "Apps", systemImageName: "app", to: &chips)
        appendChip(counts.fileCount, singular: "File", plural: "Files", systemImageName: "doc", to: &chips)
        appendChip(counts.folderCount, singular: "Folder", plural: "Folders", systemImageName: "folder", to: &chips)
        appendChip(counts.urlCount, singular: "Link", plural: "Links", systemImageName: "link", to: &chips)
        appendChip(
            counts.terminalCommandCount,
            singular: "Terminal",
            plural: "Terminal",
            systemImageName: "terminal",
            isEmphasized: true,
            to: &chips
        )
        appendChip(
            counts.vsCodeProjectCount,
            singular: "VS Code",
            plural: "VS Code",
            systemImageName: "chevron.left.forwardslash.chevron.right",
            to: &chips
        )
        appendChip(counts.shellScriptCount, singular: "Script", plural: "Scripts", systemImageName: "applescript", to: &chips)

        if windowLayoutCount > 0 {
            chips.append(WorkspaceSummaryChip(
                id: "windowRestore",
                title: isWindowRestoreEnabled ? "Windows" : "Windows off",
                systemImageName: "rectangle.3.group",
                isEmphasized: isWindowRestoreEnabled
            ))
        }

        return chips
    }

    private static func appendCount(_ count: Int, singular: String, plural: String, to parts: inout [String]) {
        guard count > 0 else {
            return
        }

        parts.append("\(count) \(count == 1 ? singular : plural)")
    }

    private static func appendNamedCount(
        _ count: Int,
        singleTitle: String,
        pluralTitle: String,
        to parts: inout [String]
    ) {
        guard count > 0 else {
            return
        }

        parts.append(count == 1 ? singleTitle : "\(count) \(pluralTitle)")
    }

    private static func appendChip(
        _ count: Int,
        singular: String,
        plural: String,
        systemImageName: String,
        isEmphasized: Bool = false,
        to chips: inout [WorkspaceSummaryChip]
    ) {
        guard count > 0 else {
            return
        }

        chips.append(WorkspaceSummaryChip(
            id: systemImageName,
            title: count == 1 ? singular : "\(count) \(plural)",
            systemImageName: systemImageName,
            isEmphasized: isEmphasized
        ))
    }

    private static func displayTitle(_ value: String?, fallbackPath: String? = nil, fallback: String) -> String {
        if let value = optionalTrimmed(value) {
            return value
        }

        if let fallbackPath = optionalTrimmed(fallbackPath) {
            let lastPathComponent = URL(fileURLWithPath: fallbackPath).lastPathComponent
            if !lastPathComponent.isEmpty {
                return lastPathComponent
            }
        }

        return fallback
    }

    private static func displayTitle(_ value: String?, fallbackURL: String, fallback: String) -> String {
        if let value = optionalTrimmed(value) {
            return value
        }

        if let host = URLComponents(string: fallbackURL)?.host, !host.isEmpty {
            return host
        }

        return optionalTrimmed(fallbackURL) ?? fallback
    }

    private static func optionalTrimmed(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
