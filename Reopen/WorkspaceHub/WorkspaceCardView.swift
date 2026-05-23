import AppKit
import SwiftUI

struct WorkspaceCardView: View {
    let workspace: Workspace
    let summary: WorkspaceSummary
    let launchStatus: WorkspaceHubLaunchStatus?
    let isSelected: Bool
    let isExpanded: Bool
    let isDeleteConfirmationPresented: Bool
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onLaunch: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onDuplicate: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onCancelDelete: () -> Void
    let onShowLaunchDetails: () -> Void
    let onRepairLaunchIssue: (ActionLaunchResult) -> Void

    @State private var isHovered = false

    private var isLaunching: Bool {
        launchStatus?.phase == .launching
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Button(action: onLaunch) {
                    mainContent
                }
                .buttonStyle(.plain)
                .disabled(isLaunching)

                cardControls
            }

            if !summary.previewItems.isEmpty || !summary.chips.isEmpty {
                visualSummary
            }

            if isDeleteConfirmationPresented {
                deleteConfirmation
            }

            if showsFailureDetails {
                failureDetails
            }
        }
        .padding(14)
        .reopenCard(isSelected: isSelected, isHovered: isHovered)
        .onHover { isHovered = $0 }
        .accessibilityElement(children: .contain)
    }

    private var mainContent: some View {
        HStack(alignment: .top, spacing: 12) {
            primaryIcon

            VStack(alignment: .leading, spacing: 5) {
                Text(summary.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                Text(summary.displayDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                launchStatusView
            }

            Spacer(minLength: 8)
        }
        .contentShape(Rectangle())
    }

    private var primaryIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: ReopenPanelMetrics.cornerRadius, style: .continuous)
                .fill(Color.accentColor.opacity(0.13))

            Image(systemName: summary.primarySystemImageName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.accentColor)
        }
        .frame(width: 42, height: 42)
    }

    @ViewBuilder
    private var launchStatusView: some View {
        if let launchStatus {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    switch launchStatus.phase {
                    case .launching:
                        ProgressView()
                            .controlSize(.small)
                            .frame(width: 14)
                    case .succeeded:
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    case .failed:
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }

                    Text(launchMessage(for: launchStatus))
                        .lineLimit(1)
                }

                if launchStatus.phase == .failed {
                    Button(action: onShowLaunchDetails) {
                        Text(isExpanded ? "Hide details" : "Show details")
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                    .font(.caption)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        } else {
            Label("Launch", systemImage: "play.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var cardControls: some View {
        HStack(spacing: 4) {
            if launchStatus?.phase == .failed {
                Button(action: onShowLaunchDetails) {
                    Image(systemName: "info.circle")
                }
                .buttonStyle(.reopenQuietIcon)
                .help("Launch Details")
            }

            Button(action: onEdit) {
                Image(systemName: "pencil")
            }
            .buttonStyle(.reopenQuietIcon)
            .help("Edit Workspace")

            Button(action: onDelete) {
                Image(systemName: isDeleteConfirmationPresented ? "trash.fill" : "trash")
            }
            .buttonStyle(.reopenQuietIcon)
            .foregroundStyle(isDeleteConfirmationPresented ? .red : .primary)
            .help("Delete Workspace")

            Menu {
                Button {
                    onDuplicate()
                } label: {
                    Label("Duplicate", systemImage: "plus.square.on.square")
                }

                Divider()

                Button {
                    onMoveUp()
                } label: {
                    Label("Move Up", systemImage: "arrow.up")
                }
                .disabled(!canMoveUp)

                Button {
                    onMoveDown()
                } label: {
                    Label("Move Down", systemImage: "arrow.down")
                }
                .disabled(!canMoveDown)
            } label: {
                Image(systemName: "ellipsis")
            }
            .menuStyle(.borderlessButton)
            .frame(width: ReopenPanelMetrics.iconButtonSize, height: ReopenPanelMetrics.iconButtonSize)
            .help("More Workspace Actions")
        }
    }

    private var visualSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !summary.previewItems.isEmpty {
                HStack(spacing: -4) {
                    ForEach(summary.previewItems.prefix(isExpanded ? 8 : 5)) { item in
                        WorkspacePreviewIconView(item: item)
                            .help(item.title)
                    }

                    if summary.previewItems.count > (isExpanded ? 8 : 5) {
                        Text("+\(summary.previewItems.count - (isExpanded ? 8 : 5))")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .frame(width: 26, height: 26)
                            .background {
                                Circle()
                                    .fill(ReopenColor.quietFill)
                            }
                            .reopenSubtleBorder(cornerRadius: 13, opacity: 0.75)
                    }
                }
            }

            if !summary.chips.isEmpty {
                HStack(spacing: 5) {
                    ForEach(summary.chips.prefix(isExpanded ? 6 : 4)) { chip in
                        ReopenChip(
                            title: chip.title,
                            systemImage: chip.systemImageName,
                            isEmphasized: chip.isEmphasized
                        )
                    }

                    if summary.chips.count > (isExpanded ? 6 : 4) {
                        ReopenChip(title: "+\(summary.chips.count - (isExpanded ? 6 : 4))", systemImage: nil)
                    }
                }
            }
        }
    }

    private var deleteConfirmation: some View {
        HStack(spacing: 8) {
            Label("Delete?", systemImage: "exclamationmark.triangle")
                .font(.caption)
                .foregroundStyle(.red)

            Spacer()

            Button(action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
            .buttonStyle(.reopenQuiet)
            .foregroundStyle(.red)
            .help("Confirm Delete")

            Button(action: onCancelDelete) {
                Image(systemName: "xmark")
            }
            .buttonStyle(.reopenQuietIcon)
            .help("Cancel Delete")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background {
            RoundedRectangle(cornerRadius: ReopenPanelMetrics.cornerRadius, style: .continuous)
                .fill(Color.red.opacity(0.08))
        }
        .reopenSubtleBorder(opacity: 0.55)
    }

    private var showsFailureDetails: Bool {
        isExpanded && failedLaunchResults.isEmpty == false
    }

    private var failedLaunchResults: [ActionLaunchResult] {
        launchStatus?.result?.allResults.filter { $0.status == .failed } ?? []
    }

    private var failureDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Needs attention")
                .reopenSectionTitle()

            ForEach(failedLaunchResults.prefix(5)) { actionResult in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "xmark.octagon.fill")
                            .foregroundStyle(.red)
                            .font(.caption)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(actionResult.title)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .lineLimit(1)

                            Text(actionResult.message)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }

                        Spacer(minLength: 0)

                        if canRepair(actionResult) {
                            Button("Repair") {
                                onRepairLaunchIssue(actionResult)
                            }
                            .buttonStyle(.reopenQuiet)
                        }
                    }

                    if let guidance = ActionFailureGuidanceProvider.guidance(for: actionResult) {
                        Text(guidance.howToFix)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .padding(.leading, 20)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: ReopenPanelMetrics.cornerRadius, style: .continuous)
                        .fill(Color.red.opacity(0.06))
                }
                .reopenSubtleBorder(opacity: 0.5)
            }
        }
    }

    private func launchMessage(for status: WorkspaceHubLaunchStatus) -> String {
        switch status.phase {
        case .launching:
            return "Launching..."
        case .succeeded, .failed:
            return status.message
        }
    }

    private func canRepair(_ actionResult: ActionLaunchResult) -> Bool {
        actionResult.errorCode == "missing_file"
            || actionResult.errorCode == "missing_folder"
            || actionResult.errorCode == "permission_file_access_missing"
    }
}

private struct WorkspacePreviewIconView: View {
    let item: WorkspaceSummaryPreviewItem

    var body: some View {
        ZStack {
            Circle()
                .fill(.regularMaterial)
                .frame(width: 28, height: 28)
                .reopenSubtleBorder(cornerRadius: 14, opacity: 0.85)

            icon
                .frame(width: 18, height: 18)
        }
    }

    @ViewBuilder
    private var icon: some View {
        if item.actionType == .openApp, let appPath = item.appPath, FileManager.default.fileExists(atPath: appPath) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: appPath))
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: item.systemImageName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }
}
