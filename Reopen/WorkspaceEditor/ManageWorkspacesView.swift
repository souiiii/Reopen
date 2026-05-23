import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ManageWorkspacesView: View {
    @ObservedObject var appState: AppState
    let workspaceManager: WorkspaceManager
    let onEdit: (Workspace) -> Void
    let onExport: (Workspace, URL) -> Void
    let onCreate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Manage Workspaces")
                .font(.title2)
                .fontWeight(.semibold)

            if appState.workspaces.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 34))
                        .foregroundStyle(.secondary)
                    Text("No workspaces yet.")
                        .font(.headline)
                    Text("Create your first workspace to reopen your work setup in one click.")
                        .foregroundStyle(.secondary)
                    Button("Create Workspace", action: onCreate)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                List(appState.workspaces) { workspace in
                    WorkspaceManagementRow(
                        workspace: workspace,
                        onEdit: {
                            if let latestWorkspace = workspaceManager.getWorkspace(id: workspace.id) {
                                onEdit(latestWorkspace)
                            }
                        },
                        onExport: {
                            if let latestWorkspace = workspaceManager.getWorkspace(id: workspace.id) {
                                export(latestWorkspace)
                            }
                        }
                    )
                }
                .listStyle(.inset)
            }
        }
        .padding(24)
    }

    private func export(_ workspace: Workspace) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = "\(workspace.name) Workspace.json"
        panel.title = "Export Workspace"

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        onExport(workspace, url)
    }
}

private struct WorkspaceManagementRow: View {
    let workspace: Workspace
    let onEdit: () -> Void
    let onExport: () -> Void

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

            Button(action: onExport) {
                Image(systemName: "square.and.arrow.up")
            }
            .buttonStyle(.borderless)
            .help("Export workspace")

            Button("Edit", action: onEdit)
        }
        .padding(.vertical, 6)
    }

    private var summary: String {
        "\(workspace.actions.count) actions"
    }
}
