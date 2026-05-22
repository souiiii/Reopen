import Foundation

enum WorkspaceCreationError: Error, Equatable {
    case emptyName
    case invalidAction(String)

    var userFacingMessage: String {
        switch self {
        case .emptyName:
            return "Workspace names cannot be empty."
        case .invalidAction(let message):
            return message
        }
    }
}

struct WorkspaceCreationDraft: Equatable {
    var id: UUID?
    var name = ""
    var icon: String?
    var color: String?
    var description = ""
    var actions: [WorkspaceActionDraft] = []
    var windowLayouts: [WindowLayout] = []
    var createdAt: Date?

    init(
        id: UUID? = nil,
        name: String = "",
        icon: String? = nil,
        color: String? = nil,
        description: String = "",
        actions: [WorkspaceActionDraft] = [],
        windowLayouts: [WindowLayout] = [],
        createdAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.description = description
        self.actions = actions
        self.windowLayouts = windowLayouts
        self.createdAt = createdAt
    }

    init(workspace: Workspace) {
        self.init(
            id: workspace.id,
            name: workspace.name,
            icon: workspace.icon,
            color: workspace.color,
            description: workspace.description ?? "",
            actions: workspace.actions.map(WorkspaceActionDraft.init(action:)),
            windowLayouts: workspace.windowLayouts,
            createdAt: workspace.createdAt
        )
    }

    var validationMessage: String? {
        do {
            _ = try makeWorkspace()
            return nil
        } catch let error as WorkspaceCreationError {
            return error.userFacingMessage
        } catch {
            return "Workspace could not be saved."
        }
    }

    func makeWorkspace() throws -> Workspace {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw WorkspaceCreationError.emptyName
        }

        return Workspace(
            id: id ?? UUID(),
            name: trimmedName,
            icon: icon,
            color: color,
            description: optionalTrimmed(description),
            actions: try actions.map { try $0.makeWorkspaceAction() },
            windowLayouts: windowLayouts,
            createdAt: createdAt ?? Date(),
            updatedAt: Date()
        )
    }

    private func optionalTrimmed(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

enum WorkspaceActionDraftKind: String, CaseIterable, Equatable {
    case openApp
    case openFile
    case openFolder
    case openURL
    case terminalCommand
    case openVSCodeProject
    case shellScript

    var title: String {
        switch self {
        case .openApp:
            return "App"
        case .openFile:
            return "File"
        case .openFolder:
            return "Folder"
        case .openURL:
            return "URL"
        case .terminalCommand:
            return "Terminal Command"
        case .openVSCodeProject:
            return "VS Code Project"
        case .shellScript:
            return "Shell Script"
        }
    }

    var systemImageName: String {
        switch self {
        case .openApp:
            return "app"
        case .openFile:
            return "doc"
        case .openFolder:
            return "folder"
        case .openURL:
            return "link"
        case .terminalCommand:
            return "terminal"
        case .openVSCodeProject:
            return "chevron.left.forwardslash.chevron.right"
        case .shellScript:
            return "applescript"
        }
    }
}

struct WorkspaceActionDraft: Identifiable, Equatable {
    var id = UUID()
    var kind: WorkspaceActionDraftKind
    var name = ""
    var path = ""
    var bundleIdentifier: String?
    var url = ""
    var displayTitle = ""
    var command = ""
    var workingDirectory = ""
    var scriptPath = ""

    var title: String {
        switch kind {
        case .openApp, .openFile, .openFolder:
            return name.isEmpty ? kind.title : name
        case .openURL:
            if !displayTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return displayTitle
            }
            return url.isEmpty ? kind.title : url
        case .terminalCommand:
            return name.isEmpty ? kind.title : name
        case .openVSCodeProject:
            return path.isEmpty ? kind.title : URL(fileURLWithPath: path).lastPathComponent
        case .shellScript:
            return name.isEmpty ? kind.title : name
        }
    }

    init(
        id: UUID = UUID(),
        kind: WorkspaceActionDraftKind,
        name: String = "",
        path: String = "",
        bundleIdentifier: String? = nil,
        url: String = "",
        displayTitle: String = "",
        command: String = "",
        workingDirectory: String = "",
        scriptPath: String = ""
    ) {
        self.id = id
        self.kind = kind
        self.name = name
        self.path = path
        self.bundleIdentifier = bundleIdentifier
        self.url = url
        self.displayTitle = displayTitle
        self.command = command
        self.workingDirectory = workingDirectory
        self.scriptPath = scriptPath
    }

    init(action: WorkspaceAction) {
        switch action {
        case .openApp(let payload):
            self.init(
                id: payload.id,
                kind: .openApp,
                name: payload.name,
                path: payload.path,
                bundleIdentifier: payload.bundleIdentifier
            )
        case .openFile(let payload):
            self.init(id: payload.id, kind: .openFile, name: payload.name, path: payload.path)
        case .openFolder(let payload):
            self.init(id: payload.id, kind: .openFolder, name: payload.name, path: payload.path)
        case .openURL(let payload):
            self.init(
                id: payload.id,
                kind: .openURL,
                url: payload.url,
                displayTitle: payload.displayTitle ?? ""
            )
        case .terminalCommand(let payload):
            self.init(
                id: payload.id,
                kind: .terminalCommand,
                name: payload.name,
                command: payload.command,
                workingDirectory: payload.workingDirectory
            )
        case .openVSCodeProject(let payload):
            self.init(
                id: payload.id,
                kind: .openVSCodeProject,
                path: payload.projectPath
            )
        case .shellScript(let payload):
            self.init(
                id: payload.id,
                kind: .shellScript,
                name: payload.name,
                workingDirectory: payload.workingDirectory ?? "",
                scriptPath: payload.scriptPath
            )
        }
    }

    static func app(name: String, path: String, bundleIdentifier: String?) -> WorkspaceActionDraft {
        WorkspaceActionDraft(
            kind: .openApp,
            name: name,
            path: path,
            bundleIdentifier: bundleIdentifier
        )
    }

    static func file(name: String, path: String) -> WorkspaceActionDraft {
        WorkspaceActionDraft(kind: .openFile, name: name, path: path)
    }

    static func folder(name: String, path: String) -> WorkspaceActionDraft {
        WorkspaceActionDraft(kind: .openFolder, name: name, path: path)
    }

    static func url() -> WorkspaceActionDraft {
        WorkspaceActionDraft(kind: .openURL, url: "https://")
    }

    static func terminalCommand() -> WorkspaceActionDraft {
        WorkspaceActionDraft(kind: .terminalCommand, name: "Command")
    }

    static func vsCodeProject(path: String) -> WorkspaceActionDraft {
        WorkspaceActionDraft(kind: .openVSCodeProject, path: path)
    }

    func makeWorkspaceAction() throws -> WorkspaceAction {
        switch kind {
        case .openApp:
            return .openApp(OpenAppAction(
                id: id,
                name: try require(name, field: "app name"),
                path: try require(path, field: "app path"),
                bundleIdentifier: bundleIdentifier
            ))
        case .openFile:
            return .openFile(OpenFileAction(
                id: id,
                name: try require(name, field: "file name"),
                path: try require(path, field: "file path")
            ))
        case .openFolder:
            return .openFolder(OpenFolderAction(
                id: id,
                name: try require(name, field: "folder name"),
                path: try require(path, field: "folder path")
            ))
        case .openURL:
            let trimmedURL = try require(url, field: "URL")
            guard trimmedURL != "https://", trimmedURL != "http://" else {
                throw WorkspaceCreationError.invalidAction("URL is missing address.")
            }

            return .openURL(OpenURLAction(
                id: id,
                url: trimmedURL,
                displayTitle: optionalTrimmed(displayTitle)
            ))
        case .terminalCommand:
            return .terminalCommand(TerminalCommandAction(
                id: id,
                name: try require(name, field: "command name"),
                command: try require(command, field: "terminal command"),
                workingDirectory: try require(workingDirectory, field: "working directory")
            ))
        case .openVSCodeProject:
            return .openVSCodeProject(OpenVSCodeProjectAction(
                id: id,
                projectPath: try require(path, field: "project folder")
            ))
        case .shellScript:
            return .shellScript(ShellScriptAction(
                id: id,
                name: try require(name, field: "script name"),
                scriptPath: try require(scriptPath, field: "script path"),
                workingDirectory: optionalTrimmed(workingDirectory)
            ))
        }
    }

    private func require(_ value: String, field: String) throws -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw WorkspaceCreationError.invalidAction("\(kind.title) is missing \(field).")
        }

        return trimmed
    }

    private func optionalTrimmed(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
