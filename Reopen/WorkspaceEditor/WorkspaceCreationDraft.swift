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
    var name = ""
    var icon: String?
    var color: String?
    var description = ""
    var actions: [WorkspaceActionDraft] = []

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
            name: trimmedName,
            icon: icon,
            color: color,
            description: optionalTrimmed(description),
            actions: try actions.map { try $0.makeWorkspaceAction() }
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
