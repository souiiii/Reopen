import Foundation

enum WorkspaceActionType: String, Codable, CaseIterable, Equatable, Sendable {
    case openApp
    case openFile
    case openFolder
    case openURL
    case terminalCommand
    case openVSCodeProject
    case shellScript
}

enum WorkspaceAction: Identifiable, Codable, Equatable, Sendable {
    case openApp(OpenAppAction)
    case openFile(OpenFileAction)
    case openFolder(OpenFolderAction)
    case openURL(OpenURLAction)
    case terminalCommand(TerminalCommandAction)
    case openVSCodeProject(OpenVSCodeProjectAction)
    case shellScript(ShellScriptAction)

    var id: UUID {
        switch self {
        case .openApp(let action):
            return action.id
        case .openFile(let action):
            return action.id
        case .openFolder(let action):
            return action.id
        case .openURL(let action):
            return action.id
        case .terminalCommand(let action):
            return action.id
        case .openVSCodeProject(let action):
            return action.id
        case .shellScript(let action):
            return action.id
        }
    }

    var type: WorkspaceActionType {
        switch self {
        case .openApp:
            return .openApp
        case .openFile:
            return .openFile
        case .openFolder:
            return .openFolder
        case .openURL:
            return .openURL
        case .terminalCommand:
            return .terminalCommand
        case .openVSCodeProject:
            return .openVSCodeProject
        case .shellScript:
            return .shellScript
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawType = try container.decode(String.self, forKey: .type)

        guard let actionType = WorkspaceActionType(rawValue: rawType) else {
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unsupported workspace action type: \(rawType)"
            )
        }

        switch actionType {
        case .openApp:
            self = .openApp(try OpenAppAction(from: decoder))
        case .openFile:
            self = .openFile(try OpenFileAction(from: decoder))
        case .openFolder:
            self = .openFolder(try OpenFolderAction(from: decoder))
        case .openURL:
            self = .openURL(try OpenURLAction(from: decoder))
        case .terminalCommand:
            self = .terminalCommand(try TerminalCommandAction(from: decoder))
        case .openVSCodeProject:
            self = .openVSCodeProject(try OpenVSCodeProjectAction(from: decoder))
        case .shellScript:
            self = .shellScript(try ShellScriptAction(from: decoder))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type.rawValue, forKey: .type)

        switch self {
        case .openApp(let action):
            try action.encode(to: encoder)
        case .openFile(let action):
            try action.encode(to: encoder)
        case .openFolder(let action):
            try action.encode(to: encoder)
        case .openURL(let action):
            try action.encode(to: encoder)
        case .terminalCommand(let action):
            try action.encode(to: encoder)
        case .openVSCodeProject(let action):
            try action.encode(to: encoder)
        case .shellScript(let action):
            try action.encode(to: encoder)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type
    }
}

struct OpenAppAction: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var name: String
    var path: String
    var bundleIdentifier: String?

    init(
        id: UUID = UUID(),
        name: String,
        path: String,
        bundleIdentifier: String? = nil
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.bundleIdentifier = bundleIdentifier
    }
}

struct OpenFileAction: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var name: String
    var path: String
    var securityScopedBookmarkData: Data?

    init(
        id: UUID = UUID(),
        name: String,
        path: String,
        securityScopedBookmarkData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.securityScopedBookmarkData = securityScopedBookmarkData
    }
}

struct OpenFolderAction: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var name: String
    var path: String
    var securityScopedBookmarkData: Data?

    init(
        id: UUID = UUID(),
        name: String,
        path: String,
        securityScopedBookmarkData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.securityScopedBookmarkData = securityScopedBookmarkData
    }
}

struct OpenURLAction: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var url: String
    var displayTitle: String?

    init(
        id: UUID = UUID(),
        url: String,
        displayTitle: String? = nil
    ) {
        self.id = id
        self.url = url
        self.displayTitle = displayTitle
    }
}

struct TerminalCommandAction: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var name: String
    var command: String
    var workingDirectory: String
    var requiresConfirmation: Bool

    init(
        id: UUID = UUID(),
        name: String,
        command: String,
        workingDirectory: String,
        requiresConfirmation: Bool = true
    ) {
        self.id = id
        self.name = name
        self.command = command
        self.workingDirectory = workingDirectory
        self.requiresConfirmation = requiresConfirmation
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        command = try container.decode(String.self, forKey: .command)
        workingDirectory = try container.decode(String.self, forKey: .workingDirectory)
        requiresConfirmation = try container.decodeIfPresent(Bool.self, forKey: .requiresConfirmation) ?? true
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case command
        case workingDirectory
        case requiresConfirmation
    }
}

struct OpenVSCodeProjectAction: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var projectPath: String
    var editor: String

    init(
        id: UUID = UUID(),
        projectPath: String,
        editor: String = "vscode"
    ) {
        self.id = id
        self.projectPath = projectPath
        self.editor = editor
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        projectPath = try container.decode(String.self, forKey: .projectPath)
        editor = try container.decodeIfPresent(String.self, forKey: .editor) ?? "vscode"
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case projectPath
        case editor
    }
}

struct ShellScriptAction: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var name: String
    var scriptPath: String
    var workingDirectory: String?
    var requiresConfirmation: Bool

    init(
        id: UUID = UUID(),
        name: String,
        scriptPath: String,
        workingDirectory: String? = nil,
        requiresConfirmation: Bool = true
    ) {
        self.id = id
        self.name = name
        self.scriptPath = scriptPath
        self.workingDirectory = workingDirectory
        self.requiresConfirmation = requiresConfirmation
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        scriptPath = try container.decode(String.self, forKey: .scriptPath)
        workingDirectory = try container.decodeIfPresent(String.self, forKey: .workingDirectory)
        requiresConfirmation = try container.decodeIfPresent(Bool.self, forKey: .requiresConfirmation) ?? true
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case scriptPath
        case workingDirectory
        case requiresConfirmation
    }
}
