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
    @Published private(set) var editLayoutMessage: String?
    @Published var createDraft = WorkspaceCreationDraft()
    @Published var editDraft = WorkspaceCreationDraft()

    func showList() {
        mode = .list
        selectedWorkspaceID = nil
        isCreateComposerPresented = false
        deleteConfirmationWorkspaceID = nil
        validationMessages.removeAll()
        createDraft = WorkspaceCreationDraft()
        editDraft = WorkspaceCreationDraft()
        editLayoutMessage = nil
    }

    func startCreating() {
        mode = .creating
        selectedWorkspaceID = nil
        expandedWorkspaceID = nil
        isCreateComposerPresented = true
        deleteConfirmationWorkspaceID = nil
        validationMessages.removeValue(forKey: .create)
        editDraft = WorkspaceCreationDraft()
        editLayoutMessage = nil
    }

    func cancelCreating() {
        mode = .list
        selectedWorkspaceID = nil
        expandedWorkspaceID = nil
        isCreateComposerPresented = false
        createDraft = WorkspaceCreationDraft()
        validationMessages.removeValue(forKey: .create)
    }

    func finishCreating(savedWorkspaceID: UUID) {
        mode = .list
        selectedWorkspaceID = savedWorkspaceID
        expandedWorkspaceID = savedWorkspaceID
        isCreateComposerPresented = false
        createDraft = WorkspaceCreationDraft()
        validationMessages.removeValue(forKey: .create)
    }

    func startEditing(workspace: Workspace) {
        let workspaceID = workspace.id
        mode = .editing(workspaceID: workspaceID)
        selectedWorkspaceID = workspaceID
        expandedWorkspaceID = workspaceID
        isCreateComposerPresented = false
        deleteConfirmationWorkspaceID = nil
        createDraft = WorkspaceCreationDraft()
        editDraft = WorkspaceCreationDraft(workspace: workspace)
        editLayoutMessage = nil
        validationMessages.removeValue(forKey: .workspace(workspaceID))
    }

    func cancelEditing() {
        mode = .list
        selectedWorkspaceID = nil
        expandedWorkspaceID = nil
        editDraft = WorkspaceCreationDraft()
        editLayoutMessage = nil
        validationMessages.removeAll()
    }

    func finishEditing(savedWorkspaceID: UUID) {
        mode = .list
        selectedWorkspaceID = savedWorkspaceID
        expandedWorkspaceID = savedWorkspaceID
        editDraft = WorkspaceCreationDraft()
        editLayoutMessage = nil
        validationMessages.removeValue(forKey: .workspace(savedWorkspaceID))
    }

    func showLaunchDetails(workspaceID: UUID) {
        mode = .launchDetails(workspaceID: workspaceID)
        selectedWorkspaceID = workspaceID
        expandedWorkspaceID = workspaceID
        isCreateComposerPresented = false
        deleteConfirmationWorkspaceID = nil
        createDraft = WorkspaceCreationDraft()
        editDraft = WorkspaceCreationDraft()
        editLayoutMessage = nil
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

    func finishDeleting(workspaceID: UUID) {
        if selectedWorkspaceID == workspaceID {
            selectedWorkspaceID = nil
        }

        if expandedWorkspaceID == workspaceID {
            expandedWorkspaceID = nil
        }

        if case .editing(let editingWorkspaceID) = mode, editingWorkspaceID == workspaceID {
            mode = .list
            editDraft = WorkspaceCreationDraft()
            editLayoutMessage = nil
        }

        deleteConfirmationWorkspaceID = nil
        validationMessages.removeValue(forKey: .workspace(workspaceID))
    }

    func finishDuplicating(savedWorkspaceID: UUID) {
        mode = .list
        selectedWorkspaceID = savedWorkspaceID
        expandedWorkspaceID = savedWorkspaceID
        deleteConfirmationWorkspaceID = nil
        validationMessages.removeAll()
    }

    func finishReordering(workspaceID: UUID) {
        selectedWorkspaceID = workspaceID
        expandedWorkspaceID = workspaceID
        deleteConfirmationWorkspaceID = nil
        validationMessages.removeValue(forKey: .workspace(workspaceID))
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

    func setEditLayoutMessage(_ message: String?) {
        editLayoutMessage = message
    }

    func updateLaunchProgress(_ snapshot: WorkspaceLaunchProgressSnapshot) {
        launchStatusesByWorkspaceID[snapshot.workspaceID] = .launching(snapshot)
    }

    func finishLaunch(_ result: WorkspaceLaunchResult) {
        launchStatusesByWorkspaceID[result.workspaceID] = .finished(result)
    }

    func clearSuccessfulLaunchStatus(workspaceID: UUID, resultID: UUID) {
        guard
            let status = launchStatusesByWorkspaceID[workspaceID],
            status.phase == .succeeded,
            status.result?.id == resultID
        else {
            return
        }

        launchStatusesByWorkspaceID.removeValue(forKey: workspaceID)
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
        createDraft = WorkspaceCreationDraft()
        editDraft = WorkspaceCreationDraft()
        editLayoutMessage = nil
    }
}
