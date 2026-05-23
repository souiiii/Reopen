import Foundation

enum WorkspaceHubCreateCoordinator {
    @MainActor
    static func saveCreateDraft(
        state: WorkspaceHubState,
        workspaceManager: WorkspaceManager
    ) {
        do {
            let workspace = try state.createDraft.makeWorkspace()
            let savedWorkspace = try workspaceManager.createWorkspace(workspace)
            state.finishCreating(savedWorkspaceID: savedWorkspace.id)
        } catch let error as WorkspaceCreationError {
            state.setValidationMessage(error.userFacingMessage, for: .create)
        } catch let error as WorkspaceManagerError {
            state.setValidationMessage(error.userFacingMessage, for: .create)
        } catch {
            state.setValidationMessage("Workspace could not be saved.", for: .create)
        }
    }
}
