import Foundation

enum WorkspaceHubManagementCoordinator {
    @MainActor
    static func deleteWorkspace(
        id workspaceID: UUID,
        state: WorkspaceHubState,
        workspaceManager: WorkspaceManager
    ) {
        do {
            try workspaceManager.deleteWorkspace(id: workspaceID, confirmed: true)
            state.finishDeleting(workspaceID: workspaceID)
        } catch let error as WorkspaceManagerError {
            state.setValidationMessage(error.userFacingMessage, for: .workspace(workspaceID))
        } catch {
            state.setValidationMessage("Workspace could not be deleted.", for: .workspace(workspaceID))
        }
    }

    @MainActor
    static func duplicateWorkspace(
        id workspaceID: UUID,
        state: WorkspaceHubState,
        workspaceManager: WorkspaceManager
    ) {
        do {
            let duplicate = try workspaceManager.duplicateWorkspace(id: workspaceID)
            state.finishDuplicating(savedWorkspaceID: duplicate.id)
        } catch let error as WorkspaceManagerError {
            state.setValidationMessage(error.userFacingMessage, for: .workspace(workspaceID))
        } catch {
            state.setValidationMessage("Workspace could not be duplicated.", for: .workspace(workspaceID))
        }
    }

    @MainActor
    static func moveWorkspace(
        id workspaceID: UUID,
        offset: Int,
        state: WorkspaceHubState,
        workspaceManager: WorkspaceManager
    ) {
        let workspaces = workspaceManager.getAllWorkspaces()
        guard
            let currentIndex = workspaces.firstIndex(where: { $0.id == workspaceID }),
            workspaces.indices.contains(currentIndex + offset)
        else {
            return
        }

        var orderedIDs = workspaces.map(\.id)
        orderedIDs.swapAt(currentIndex, currentIndex + offset)

        do {
            try workspaceManager.reorderWorkspaces(ids: orderedIDs)
            state.finishReordering(workspaceID: workspaceID)
        } catch let error as WorkspaceManagerError {
            state.setValidationMessage(error.userFacingMessage, for: .workspace(workspaceID))
        } catch {
            state.setValidationMessage("Workspace order could not be saved.", for: .workspace(workspaceID))
        }
    }
}
