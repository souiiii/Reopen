import SwiftUI

struct ManageWorkspacesView: View {
    @ObservedObject var appState: AppState
    let workspaceManager: WorkspaceManager
    let onEdit: (Workspace) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Manage Workspaces")
                .font(.title2)
                .fontWeight(.semibold)

            if appState.workspaces.isEmpty {
                Text("No workspaces yet.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                List(appState.workspaces) { workspace in
                    WorkspaceManagementRow(
                        workspace: workspace,
                        onEdit: {
                            if let latestWorkspace = workspaceManager.getWorkspace(id: workspace.id) {
                                onEdit(latestWorkspace)
                            }
                        }
                    )
                }
                .listStyle(.inset)
            }
        }
        .padding(24)
    }
}

private struct WorkspaceManagementRow: View {
    let workspace: Workspace
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(workspace.name)
                    .font(.headline)
                Text(summary)
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }

            Spacer()

            Button("Edit", action: onEdit)
        }
        .padding(.vertical, 6)
    }

    private var summary: String {
        "\(workspace.actions.count) actions"
    }
}
