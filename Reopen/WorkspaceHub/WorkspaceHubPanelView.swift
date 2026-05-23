import SwiftUI

struct WorkspaceHubPanelView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var state: WorkspaceHubState
    let onLaunchWorkspace: (UUID) -> Void
    let onSaveCreateWorkspace: () -> Void
    let onSaveEditWorkspace: () -> Void
    let onCaptureEditWindowLayout: () -> Void
    let onDeleteWorkspace: (UUID) -> Void
    let onDuplicateWorkspace: (UUID) -> Void
    let onMoveWorkspace: (UUID, Int) -> Void
    let onRepairLaunchIssue: (UUID, ActionLaunchResult) -> Void
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
        .onExitCommand {
            state.cancelDeleteConfirmation()
        }
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
        case .list, .creating, .editing:
            workspaceListContent
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

    private var workspaceListContent: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                if showsCreateComposer {
                    WorkspaceCreateComposerView(
                        draft: $state.createDraft,
                        isExpanded: state.isCreateComposerPresented,
                        validationMessage: state.validationMessage(for: .create),
                        onExpand: {
                            state.startCreating()
                        },
                        onSave: onSaveCreateWorkspace,
                        onCancel: {
                            state.cancelCreating()
                        }
                    )
                }

                if appState.workspaces.isEmpty && !state.isCreateComposerPresented {
                    emptyState
                }

                ForEach(appState.workspaces) { workspace in
                    workspaceCard(workspace)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
    }

    private var emptyState: some View {
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
        }
        .reopenEmptyStateStyle()
        .frame(minHeight: 280)
    }

    private var footer: some View {
        WorkspaceHubFooterView(
            onOpenSettings: onOpenSettings,
            onQuit: onQuit
        )
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

    @ViewBuilder
    private func workspaceCard(_ workspace: Workspace) -> some View {
        let summary = WorkspaceSummaryBuilder.summary(for: workspace)
        let isEditing = isEditingWorkspace(workspace.id)

        VStack(spacing: 8) {
            WorkspaceCardView(
                workspace: workspace,
                summary: summary,
                launchStatus: state.launchStatusesByWorkspaceID[workspace.id],
                isSelected: workspace.id == state.selectedWorkspaceID,
                isExpanded: workspace.id == state.expandedWorkspaceID,
                isDeleteConfirmationPresented: workspace.id == state.deleteConfirmationWorkspaceID,
                canMoveUp: canMoveWorkspace(workspace.id, offset: -1),
                canMoveDown: canMoveWorkspace(workspace.id, offset: 1),
                onLaunch: {
                    onLaunchWorkspace(workspace.id)
                },
                onEdit: {
                    state.startEditing(workspace: workspace)
                },
                onDelete: {
                    if state.deleteConfirmationWorkspaceID == workspace.id {
                        onDeleteWorkspace(workspace.id)
                    } else {
                        state.beginDeleteConfirmation(workspaceID: workspace.id)
                    }
                },
                onDuplicate: {
                    onDuplicateWorkspace(workspace.id)
                },
                onMoveUp: {
                    onMoveWorkspace(workspace.id, -1)
                },
                onMoveDown: {
                    onMoveWorkspace(workspace.id, 1)
                },
                onCancelDelete: {
                    state.cancelDeleteConfirmation()
                },
                onShowLaunchDetails: {
                    state.toggleExpandedCard(workspaceID: workspace.id)
                },
                onRepairLaunchIssue: { actionResult in
                    onRepairLaunchIssue(workspace.id, actionResult)
                }
            )

            if isEditing {
                WorkspaceCreateComposerView(
                    draft: $state.editDraft,
                    title: "Edit Workspace",
                    systemImage: "pencil.circle.fill",
                    saveButtonTitle: "Save",
                    showsCollapsedCard: false,
                    showsWindowRestoreControls: true,
                    layoutMessage: state.editLayoutMessage,
                    isExpanded: true,
                    validationMessage: state.validationMessage(for: .workspace(workspace.id)),
                    onExpand: {},
                    onSave: onSaveEditWorkspace,
                    onCancel: {
                        state.cancelEditing()
                    },
                    onCaptureWindowLayout: onCaptureEditWindowLayout
                )
            }
        }
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
        if case .editing = state.mode {
            return false
        }

        if case .launchDetails = state.mode {
            return false
        }

        if case .list = state.mode {
            return true
        }

        if case .creating = state.mode {
            return true
        }

        return false
    }

    private var showsCreateComposer: Bool {
        if case .editing = state.mode {
            return false
        }

        return true
    }

    private func isEditingWorkspace(_ workspaceID: UUID) -> Bool {
        if case .editing(let editingWorkspaceID) = state.mode {
            return editingWorkspaceID == workspaceID
        }

        return false
    }

    private func canMoveWorkspace(_ workspaceID: UUID, offset: Int) -> Bool {
        guard let currentIndex = appState.workspaces.firstIndex(where: { $0.id == workspaceID }) else {
            return false
        }

        return appState.workspaces.indices.contains(currentIndex + offset)
    }
}
