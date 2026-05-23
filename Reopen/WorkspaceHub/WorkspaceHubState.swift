import Combine
import Foundation

enum WorkspaceHubMode: Equatable {
    case list
    case creating
    case editing(workspaceID: UUID)
    case launchDetails(workspaceID: UUID)
}

enum WorkspaceHubValidationScope: Hashable {
    case create
    case workspace(UUID)
}

enum WorkspaceHubLaunchPhase: Equatable {
    case launching
    case succeeded
    case failed
}

struct WorkspaceHubLaunchStatus: Equatable {
    var phase: WorkspaceHubLaunchPhase
    var message: String
    var progressFraction: Double
    var snapshot: WorkspaceLaunchProgressSnapshot?
    var result: WorkspaceLaunchResult?

    static func launching(_ snapshot: WorkspaceLaunchProgressSnapshot) -> WorkspaceHubLaunchStatus {
        WorkspaceHubLaunchStatus(
            phase: .launching,
            message: snapshot.message,
            progressFraction: snapshot.progressFraction,
            snapshot: snapshot,
            result: nil
        )
    }

    static func finished(_ result: WorkspaceLaunchResult) -> WorkspaceHubLaunchStatus {
        WorkspaceHubLaunchStatus(
            phase: result.hasFailures ? .failed : .succeeded,
            message: result.hasFailures ? "Some items failed" : "Launched",
            progressFraction: 1,
            snapshot: nil,
            result: result
        )
    }
}

@MainActor
final class WorkspaceHubState: ObservableObject {
    @Published private(set) var mode: WorkspaceHubMode = .list
    @Published private(set) var selectedWorkspaceID: UUID?
    @Published private(set) var expandedWorkspaceID: UUID?
    @Published private(set) var isCreateComposerPresented = false
    @Published private(set) var deleteConfirmationWorkspaceID: UUID?
    @Published private(set) var launchStatusesByWorkspaceID: [UUID: WorkspaceHubLaunchStatus] = [:]
    @Published private(set) var validationMessages: [WorkspaceHubValidationScope: String] = [:]

    func showList() {
        mode = .list
        selectedWorkspaceID = nil
        isCreateComposerPresented = false
        deleteConfirmationWorkspaceID = nil
        validationMessages.removeAll()
    }

    func startCreating() {
        mode = .creating
        selectedWorkspaceID = nil
        expandedWorkspaceID = nil
        isCreateComposerPresented = true
        deleteConfirmationWorkspaceID = nil
        validationMessages.removeValue(forKey: .create)
    }

    func startEditing(workspaceID: UUID) {
        mode = .editing(workspaceID: workspaceID)
        selectedWorkspaceID = workspaceID
        expandedWorkspaceID = workspaceID
        isCreateComposerPresented = false
        deleteConfirmationWorkspaceID = nil
        validationMessages.removeValue(forKey: .workspace(workspaceID))
    }

    func showLaunchDetails(workspaceID: UUID) {
        mode = .launchDetails(workspaceID: workspaceID)
        selectedWorkspaceID = workspaceID
        expandedWorkspaceID = workspaceID
        isCreateComposerPresented = false
        deleteConfirmationWorkspaceID = nil
    }

    func selectWorkspace(_ workspaceID: UUID?) {
        selectedWorkspaceID = workspaceID
    }

    func toggleExpandedCard(workspaceID: UUID) {
        expandedWorkspaceID = expandedWorkspaceID == workspaceID ? nil : workspaceID
    }

    func setExpandedCard(workspaceID: UUID?) {
        expandedWorkspaceID = workspaceID
    }

    func beginDeleteConfirmation(workspaceID: UUID) {
        deleteConfirmationWorkspaceID = workspaceID
        selectedWorkspaceID = workspaceID
    }

    func cancelDeleteConfirmation() {
        deleteConfirmationWorkspaceID = nil
    }

    func setValidationMessage(_ message: String?, for scope: WorkspaceHubValidationScope) {
        if let message {
            validationMessages[scope] = message
        } else {
            validationMessages.removeValue(forKey: scope)
        }
    }

    func validationMessage(for scope: WorkspaceHubValidationScope) -> String? {
        validationMessages[scope]
    }

    func updateLaunchProgress(_ snapshot: WorkspaceLaunchProgressSnapshot) {
        launchStatusesByWorkspaceID[snapshot.workspaceID] = .launching(snapshot)
    }

    func finishLaunch(_ result: WorkspaceLaunchResult) {
        launchStatusesByWorkspaceID[result.workspaceID] = .finished(result)
    }

    func clearLaunchStatus(workspaceID: UUID) {
        launchStatusesByWorkspaceID.removeValue(forKey: workspaceID)
    }

    func resetForPanelClose() {
        mode = .list
        selectedWorkspaceID = nil
        expandedWorkspaceID = nil
        isCreateComposerPresented = false
        deleteConfirmationWorkspaceID = nil
        launchStatusesByWorkspaceID.removeAll()
        validationMessages.removeAll()
    }
}
