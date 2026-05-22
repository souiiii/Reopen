import Foundation

enum ActionLaunchStatus: String, Codable, Equatable {
    case succeeded
    case failed
    case skipped
}

struct ActionLaunchResult: Identifiable, Codable, Equatable {
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

struct WorkspaceLaunchResult: Identifiable, Codable, Equatable {
    let id: UUID
    var workspaceID: UUID
    var workspaceName: String
    var startedAt: Date
    var finishedAt: Date?
    var actionResults: [ActionLaunchResult]

    init(
        id: UUID = UUID(),
        workspaceID: UUID,
        workspaceName: String,
        startedAt: Date = Date(),
        finishedAt: Date? = nil,
        actionResults: [ActionLaunchResult] = []
    ) {
        self.id = id
        self.workspaceID = workspaceID
        self.workspaceName = workspaceName
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.actionResults = actionResults
    }

    var hasFailures: Bool {
        actionResults.contains { $0.status == .failed }
    }
}
