import Foundation

enum ActionLaunchStatus: String, Codable, Equatable, Sendable {
    case succeeded
    case failed
    case skipped
}

enum WorkspaceLaunchProgressStage: String, Codable, Equatable, Sendable {
    case preparing
    case validating
    case checkingPermissions
    case openingApps
    case openingFiles
    case openingFolders
    case openingURLs
    case openingCodeProjects
    case runningTerminalCommands
    case waitingForWindows
    case applyingWindowLayout
    case finished
}

struct ActionLaunchResult: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var actionID: UUID?
    var actionType: String
    var title: String
    var status: ActionLaunchStatus
    var message: String
    var errorCode: String?

    init(
        id: UUID = UUID(),
        actionID: UUID? = nil,
        actionType: String,
        title: String,
        status: ActionLaunchStatus,
        message: String,
        errorCode: String? = nil
    ) {
        self.id = id
        self.actionID = actionID
        self.actionType = actionType
        self.title = title
        self.status = status
        self.message = message
        self.errorCode = errorCode
    }
}

struct WorkspaceLaunchResult: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var workspaceID: UUID
    var workspaceName: String
    var startedAt: Date
    var finishedAt: Date?
    var actionResults: [ActionLaunchResult]
    var layoutResults: [ActionLaunchResult]

    init(
        id: UUID = UUID(),
        workspaceID: UUID,
        workspaceName: String,
        startedAt: Date = Date(),
        finishedAt: Date? = nil,
        actionResults: [ActionLaunchResult] = [],
        layoutResults: [ActionLaunchResult] = []
    ) {
        self.id = id
        self.workspaceID = workspaceID
        self.workspaceName = workspaceName
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.actionResults = actionResults
        self.layoutResults = layoutResults
    }

    var allResults: [ActionLaunchResult] {
        actionResults + layoutResults
    }

    var hasFailures: Bool {
        allResults.contains { $0.status == .failed }
    }
}

struct WorkspaceLaunchProgressSnapshot: Identifiable, Equatable, Sendable {
    let id: UUID
    var workspaceID: UUID
    var workspaceName: String
    var stage: WorkspaceLaunchProgressStage
    var message: String
    var completedUnits: Int
    var totalUnits: Int
    var actionResults: [ActionLaunchResult]
    var layoutResults: [ActionLaunchResult]

    init(
        id: UUID = UUID(),
        workspaceID: UUID,
        workspaceName: String,
        stage: WorkspaceLaunchProgressStage,
        message: String,
        completedUnits: Int = 0,
        totalUnits: Int = 1,
        actionResults: [ActionLaunchResult] = [],
        layoutResults: [ActionLaunchResult] = []
    ) {
        self.id = id
        self.workspaceID = workspaceID
        self.workspaceName = workspaceName
        self.stage = stage
        self.message = message
        self.completedUnits = completedUnits
        self.totalUnits = max(totalUnits, 1)
        self.actionResults = actionResults
        self.layoutResults = layoutResults
    }

    var progressFraction: Double {
        guard totalUnits > 0 else {
            return 0
        }

        return min(Double(completedUnits) / Double(totalUnits), 1)
    }

    var allResults: [ActionLaunchResult] {
        actionResults + layoutResults
    }
}
