import SwiftUI

struct WorkspaceHubPanelView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var state: WorkspaceHubState

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: ReopenPanelMetrics.width, height: ReopenPanelMetrics.height)
        .reopenPanelBackground()
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.clockwise.circle.fill")
                .font(.title2)
                .foregroundColor(.accentColor)

            Text("Reopen")
                .reopenPanelTitle()

            Spacer()

            Button {
                state.startCreating()
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.reopenQuietIcon)
            .help("New Workspace")
        }
        .padding(.horizontal, ReopenPanelMetrics.horizontalPadding)
        .padding(.vertical, ReopenPanelMetrics.verticalPadding)
        .accessibilityLabel("Reopen")
    }

    @ViewBuilder
    private var content: some View {
        switch state.mode {
        case .list:
            listContent
        case .creating:
            modeContent(
                title: "New Workspace",
                systemImage: "plus.circle",
                validationMessage: state.validationMessage(for: .create)
            )
        case .editing(let workspaceID):
            modeContent(
                title: "Edit \(workspaceTitle(for: workspaceID))",
                systemImage: "pencil.circle",
                validationMessage: state.validationMessage(for: .workspace(workspaceID))
            )
        case .launchDetails(let workspaceID):
            let status = state.launchStatusesByWorkspaceID[workspaceID]
            modeContent(
                title: workspaceTitle(for: workspaceID),
                systemImage: "play.circle",
                subtitle: status?.message,
                validationMessage: nil
            )
        }
    }

    private var listContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            if appState.workspaces.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 34))
                        .foregroundStyle(.secondary)
                    Text("No workspaces yet")
                        .font(.headline)
                    Text("Create a workspace to keep the apps, files, links, and commands you reopen often.")
                        .reopenBodySecondary()
                    Button {
                        state.startCreating()
                    } label: {
                        Label("New Workspace", systemImage: "plus")
                    }
                    .buttonStyle(.reopenPrimary)
                }
                .reopenEmptyStateStyle()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        Text("Workspaces")
                            .reopenSectionTitle()
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach(appState.workspaces) { workspace in
                            workspaceNavigationRow(workspace)
                        }
                    }
                    .padding(14)
                }
            }
        }
    }

    private func modeContent(
        title: String,
        systemImage: String,
        subtitle: String? = nil,
        validationMessage: String?
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                state.showList()
            } label: {
                Label("Back", systemImage: "chevron.left")
            }
            .buttonStyle(.reopenQuiet)

            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.semibold)

                    if let subtitle {
                        Text(subtitle)
                            .reopenBodySecondary()
                    }
                }
            }

            if let validationMessage {
                Text(validationMessage)
                    .foregroundStyle(.red)
                    .font(.footnote)
            }

            Spacer()
        }
        .padding(ReopenPanelMetrics.horizontalPadding)
    }

    private func workspaceNavigationRow(_ workspace: Workspace) -> some View {
        HStack(spacing: 10) {
            Button {
                state.selectWorkspace(workspace.id)
                state.toggleExpandedCard(workspaceID: workspace.id)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: workspace.icon ?? "square.grid.2x2")
                        .foregroundStyle(.secondary)
                        .frame(width: 22)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(workspace.name)
                            .fontWeight(.medium)
                        if let status = state.launchStatusesByWorkspaceID[workspace.id] {
                            Text(status.message)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                state.startEditing(workspaceID: workspace.id)
            } label: {
                Image(systemName: "pencil")
            }
            .buttonStyle(.reopenQuietIcon)
            .help("Edit Workspace")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .reopenCard(isSelected: workspace.id == state.selectedWorkspaceID)
    }

    private func workspaceTitle(for workspaceID: UUID) -> String {
        appState.workspaces.first(where: { $0.id == workspaceID })?.name ?? "Workspace"
    }
}
