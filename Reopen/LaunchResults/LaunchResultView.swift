import SwiftUI

struct LaunchResultView: View {
    let result: WorkspaceLaunchResult
    let onRepair: (ActionLaunchResult) -> Void
    let onOpenPermissionSettings: (PermissionKind) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(result.workspaceName) launched")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(result.hasFailures ? "Some actions need attention." : "Launch actions finished.")
                    .foregroundStyle(.secondary)
            }

            if !permissionKinds.isEmpty {
                PermissionOnboardingView(
                    kinds: permissionKinds,
                    onOpenSettings: onOpenPermissionSettings
                )
            }

            List(result.allResults) { actionResult in
                HStack(alignment: .top, spacing: 12) {
                    Label(statusLabel(for: actionResult.status), systemImage: statusIcon(for: actionResult.status))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(statusColor(for: actionResult.status))
                        .frame(width: 92, alignment: .leading)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(actionResult.title)
                            .fontWeight(.medium)
                        Text(actionResult.message)
                            .foregroundStyle(.secondary)

                        if let guidance = ActionFailureGuidanceProvider.guidance(for: actionResult) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(guidance.whatFailed)
                                Text(guidance.whyItMayHaveFailed)
                                Text(guidance.howToFix)
                                    .fontWeight(.medium)
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                        }
                    }

                    Spacer()

                    if canRepair(actionResult) {
                        Button("Repair") {
                            onRepair(actionResult)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .listStyle(.inset)
        }
        .padding(24)
    }

    private var permissionKinds: [PermissionKind] {
        PermissionKind.allCases.filter { kind in
            kind != .fileAccess && result.allResults.contains { actionResult in
                PermissionKind.kind(for: actionResult.errorCode) == kind
            }
        }
    }

    private func statusLabel(for status: ActionLaunchStatus) -> String {
        switch status {
        case .succeeded:
            return "Done"
        case .failed:
            return "Failed"
        case .skipped:
            return "Skipped"
        }
    }

    private func statusIcon(for status: ActionLaunchStatus) -> String {
        switch status {
        case .succeeded:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.octagon.fill"
        case .skipped:
            return "minus.circle.fill"
        }
    }

    private func statusColor(for status: ActionLaunchStatus) -> Color {
        switch status {
        case .succeeded:
            return .green
        case .failed:
            return .red
        case .skipped:
            return .orange
        }
    }

    private func canRepair(_ actionResult: ActionLaunchResult) -> Bool {
        actionResult.errorCode == "missing_file"
            || actionResult.errorCode == "missing_folder"
            || actionResult.errorCode == "permission_file_access_missing"
    }

}
