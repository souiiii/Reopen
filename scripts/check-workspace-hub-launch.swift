import Foundation

enum WorkspaceHubLaunchCheckFailure: Error, CustomStringConvertible {
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
        throw WorkspaceHubLaunchCheckFailure.message(message)
    }
}

@main
enum WorkspaceHubLaunchChecks {
    @MainActor
    static func main() throws {
        try successfulLaunchCanBeClearedByMatchingResult()
        try failedLaunchRemainsAvailableForInlineDetails()
        try launchProgressStaysInline()

        print("Workspace hub launch checks passed.")
    }

    @MainActor
    private static func successfulLaunchCanBeClearedByMatchingResult() throws {
        let state = WorkspaceHubState()
        let workspaceID = UUID()
        let result = WorkspaceLaunchResult(
            workspaceID: workspaceID,
            workspaceName: "Coding",
            actionResults: [
                ActionLaunchResult(
                    actionType: "openURL",
                    title: "Example",
                    status: .succeeded,
                    message: "Opened."
                )
            ]
        )

        state.finishLaunch(result)
        try check(state.launchStatusesByWorkspaceID[workspaceID]?.phase == .succeeded, "Successful launch should be tracked inline.")

        state.clearSuccessfulLaunchStatus(workspaceID: workspaceID, resultID: UUID())
        try check(state.launchStatusesByWorkspaceID[workspaceID] != nil, "Unrelated success clear should not remove current status.")

        state.clearSuccessfulLaunchStatus(workspaceID: workspaceID, resultID: result.id)
        try check(state.launchStatusesByWorkspaceID[workspaceID] == nil, "Matching successful launch should clear back to normal.")
    }

    @MainActor
    private static func failedLaunchRemainsAvailableForInlineDetails() throws {
        let state = WorkspaceHubState()
        let workspaceID = UUID()
        let result = WorkspaceLaunchResult(
            workspaceID: workspaceID,
            workspaceName: "Coding",
            actionResults: [
                ActionLaunchResult(
                    actionID: UUID(),
                    actionType: WorkspaceActionType.openFile.rawValue,
                    title: "Brief.pdf",
                    status: .failed,
                    message: "File was missing.",
                    errorCode: "missing_file"
                )
            ]
        )

        state.finishLaunch(result)
        state.clearSuccessfulLaunchStatus(workspaceID: workspaceID, resultID: result.id)

        let status = state.launchStatusesByWorkspaceID[workspaceID]
        try check(status?.phase == .failed, "Failed launch should remain visible.")
        try check(status?.result?.allResults.first?.errorCode == "missing_file", "Failed launch should retain repair details.")
    }

    @MainActor
    private static func launchProgressStaysInline() throws {
        let state = WorkspaceHubState()
        let workspaceID = UUID()
        let snapshot = WorkspaceLaunchProgressSnapshot(
            workspaceID: workspaceID,
            workspaceName: "Coding",
            stage: .openingURLs,
            message: "Opening links...",
            completedUnits: 1,
            totalUnits: 3
        )

        state.updateLaunchProgress(snapshot)

        let status = state.launchStatusesByWorkspaceID[workspaceID]
        try check(status?.phase == .launching, "Launch progress should be represented as inline card state.")
        try check(status?.snapshot == snapshot, "Inline launch progress should preserve the latest snapshot.")
    }
}
