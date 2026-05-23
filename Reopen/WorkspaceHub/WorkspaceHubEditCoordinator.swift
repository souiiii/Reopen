import Foundation

enum WorkspaceHubEditCoordinator {
    @MainActor
    static func saveEditDraft(
        state: WorkspaceHubState,
        workspaceManager: WorkspaceManager
    ) {
        guard case .editing(let workspaceID) = state.mode else {
            return
        }

        do {
            let workspace = try state.editDraft.makeWorkspace()
            let savedWorkspace = try workspaceManager.updateWorkspace(workspace)
            state.finishEditing(savedWorkspaceID: savedWorkspace.id)
        } catch let error as WorkspaceCreationError {
            state.setValidationMessage(error.userFacingMessage, for: .workspace(workspaceID))
        } catch let error as WorkspaceManagerError {
            state.setValidationMessage(error.userFacingMessage, for: .workspace(workspaceID))
        } catch {
            state.setValidationMessage("Workspace could not be saved.", for: .workspace(workspaceID))
        }
    }
}
