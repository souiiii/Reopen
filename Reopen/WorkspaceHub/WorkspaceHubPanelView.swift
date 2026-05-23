import SwiftUI

struct WorkspaceHubPanelView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var state: WorkspaceHubState
    let onLaunchWorkspace: (UUID) -> Void
    let onOpenSettings: () -> Void
    let onQuit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if showsFooter {
                Divider()
                footer
            }
        }
        .frame(width: ReopenPanelMetrics.width, height: ReopenPanelMetrics.height)
        .reopenPanelBackground()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Reopen")
                        .reopenPanelTitle()

                    Text(workspaceCountText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    state.startCreating()
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.reopenQuietIcon)
                .help("New Workspace")
            }

            if let storageErrorMessage = appState.storageErrorMessage {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)

                    Text(storageErrorMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: ReopenPanelMetrics.cornerRadius, style: .continuous)
                        .fill(Color.orange.opacity(0.08))
                }
                .reopenSubtleBorder(opacity: 0.55)
            }
        }
        .padding(.horizontal, ReopenPanelMetrics.horizontalPadding)
        .padding(.top, ReopenPanelMetrics.verticalPadding)
        .padding(.bottom, 12)
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
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.accentColor.opacity(0.12))
                            .frame(width: 58, height: 58)

                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundColor(.accentColor)
                    }

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
                    LazyVStack(spacing: 10) {
                        ForEach(appState.workspaces) { workspace in
                            workspaceCard(workspace)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Button(action: onOpenSettings) {
                Label("Settings", systemImage: "gearshape")
            }
            .buttonStyle(.reopenQuiet)
            .help("Settings")

            Spacer()

            Button(action: onQuit) {
                Label("Quit", systemImage: "power")
            }
            .buttonStyle(.reopenQuiet)
            .help("Quit Reopen")
        }
        .padding(.horizontal, ReopenPanelMetrics.horizontalPadding)
        .padding(.vertical, 12)
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

    private func workspaceCard(_ workspace: Workspace) -> some View {
        let summary = WorkspaceSummaryBuilder.summary(for: workspace)

        return WorkspaceCardView(
            workspace: workspace,
            summary: summary,
            launchStatus: state.launchStatusesByWorkspaceID[workspace.id],
            isSelected: workspace.id == state.selectedWorkspaceID,
            isExpanded: workspace.id == state.expandedWorkspaceID,
            isDeleteConfirmationPresented: workspace.id == state.deleteConfirmationWorkspaceID,
            onLaunch: {
                onLaunchWorkspace(workspace.id)
            },
            onEdit: {
                state.startEditing(workspaceID: workspace.id)
            },
            onDelete: {
                state.beginDeleteConfirmation(workspaceID: workspace.id)
            },
            onCancelDelete: {
                state.cancelDeleteConfirmation()
            },
            onShowLaunchDetails: {
                state.showLaunchDetails(workspaceID: workspace.id)
            }
        )
    }

    private func workspaceTitle(for workspaceID: UUID) -> String {
        appState.workspaces.first(where: { $0.id == workspaceID })?.name ?? "Workspace"
    }

    private var workspaceCountText: String {
        switch appState.workspaces.count {
        case 0:
            return "No workspaces"
        case 1:
            return "1 workspace"
        default:
            return "\(appState.workspaces.count) workspaces"
        }
    }

    private var showsFooter: Bool {
        if case .list = state.mode {
            return true
        }

        return false
    }
}
