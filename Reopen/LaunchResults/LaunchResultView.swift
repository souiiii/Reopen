import SwiftUI

struct LaunchResultView: View {
    let result: WorkspaceLaunchResult
    let onRepair: (ActionLaunchResult) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(result.workspaceName) launched")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(result.hasFailures ? "Some actions need attention." : "Launch actions finished.")
                    .foregroundStyle(.secondary)
            }

            List(result.allResults) { actionResult in
                HStack(alignment: .top, spacing: 12) {
                    Text(statusLabel(for: actionResult.status))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(width: 72, alignment: .leading)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(actionResult.title)
                            .fontWeight(.medium)
                        Text(actionResult.message)
                            .foregroundStyle(.secondary)
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

    private func statusLabel(for status: ActionLaunchStatus) -> String {
        switch status {
        case .succeeded:
            return "Opened"
        case .failed:
            return "Failed"
        case .skipped:
            return "Skipped"
        }
    }

    private func canRepair(_ actionResult: ActionLaunchResult) -> Bool {
        actionResult.errorCode == "missing_file" || actionResult.errorCode == "missing_folder"
    }
}
