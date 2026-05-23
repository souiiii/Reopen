import Foundation

enum WorkspaceHubStateCheckFailure: Error, CustomStringConvertible {
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
        throw WorkspaceHubStateCheckFailure.message(message)
    }
}

@main
enum WorkspaceHubStateChecks {
    @MainActor
    static func main() throws {
        try createComposerCancelClearsDraft()
        try createComposerFinishClearsDraftAndSelectsWorkspace()
        try leavingCreateComposerClearsDraft()
        try cancelEditingClearsDraft()

        print("Workspace hub state checks passed.")
    }

    @MainActor
    private static func createComposerCancelClearsDraft() throws {
        let state = WorkspaceHubState()

        state.startCreating()
        state.createDraft.name = "Draft Name"
        state.createDraft.description = "Unsaved"
        state.setValidationMessage("Try again", for: .create)
        state.cancelCreating()

        try check(state.mode == .list, "Cancel should return the hub to the workspace list.")
        try check(!state.isCreateComposerPresented, "Cancel should collapse the create composer.")
        try check(state.createDraft == WorkspaceCreationDraft(), "Cancel should clear unsaved draft data.")
        try check(state.validationMessage(for: .create) == nil, "Cancel should clear create validation messages.")
    }

    @MainActor
    private static func createComposerFinishClearsDraftAndSelectsWorkspace() throws {
        let state = WorkspaceHubState()
        let savedWorkspaceID = UUID()

        state.startCreating()
        state.createDraft.name = "Saved Name"
        state.finishCreating(savedWorkspaceID: savedWorkspaceID)

        try check(state.mode == .list, "Saving should return the hub to the workspace list.")
        try check(!state.isCreateComposerPresented, "Saving should collapse the create composer.")
        try check(state.createDraft == WorkspaceCreationDraft(), "Saving should clear the draft.")
        try check(state.selectedWorkspaceID == savedWorkspaceID, "Saving should select the created workspace.")
        try check(state.expandedWorkspaceID == savedWorkspaceID, "Saving should expand the created workspace.")
    }

    @MainActor
    private static func leavingCreateComposerClearsDraft() throws {
        let state = WorkspaceHubState()
        let workspace = Workspace(
            id: UUID(),
            name: "Coding",
            actions: [.openURL(OpenURLAction(url: "https://example.com"))]
        )
        let workspaceID = workspace.id

        state.startCreating()
        state.createDraft.name = "Hidden Draft"
        state.startEditing(workspace: workspace)

        try check(!state.isCreateComposerPresented, "Editing should collapse the create composer.")
        try check(state.createDraft == WorkspaceCreationDraft(), "Leaving create mode should clear unsaved draft data.")
        try check(state.editDraft == WorkspaceCreationDraft(workspace: workspace), "Editing should load the selected workspace into a draft.")

        state.startCreating()
        state.createDraft.name = "Launch Draft"
        state.showLaunchDetails(workspaceID: workspaceID)

        try check(!state.isCreateComposerPresented, "Launch details should collapse the create composer.")
        try check(state.createDraft == WorkspaceCreationDraft(), "Launch details should clear unsaved draft data.")
    }

    @MainActor
    private static func cancelEditingClearsDraft() throws {
        let state = WorkspaceHubState()
        let workspace = Workspace(name: "Writing")

        state.startEditing(workspace: workspace)
        state.editDraft.name = "Unsaved"
        state.setEditLayoutMessage("Saved windows: 2")
        state.cancelEditing()

        try check(state.mode == .list, "Cancel editing should return to the list.")
        try check(state.editDraft == WorkspaceCreationDraft(), "Cancel editing should clear the edit draft.")
        try check(state.editLayoutMessage == nil, "Cancel editing should clear layout messages.")
    }
}
