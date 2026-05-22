import SwiftUI

@MainActor
final class LaunchProgressState: ObservableObject {
    @Published var snapshot: WorkspaceLaunchProgressSnapshot

    init(snapshot: WorkspaceLaunchProgressSnapshot) {
        self.snapshot = snapshot
    }
}

struct LaunchProgressView: View {
    @ObservedObject var state: LaunchProgressState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Launching \(state.snapshot.workspaceName)")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(state.snapshot.message)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: state.snapshot.progressFraction)
                .progressViewStyle(.linear)

            if state.snapshot.allResults.isEmpty {
                Text("Preparing launch...")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 10)
            } else {
                List(state.snapshot.allResults) { actionResult in
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
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.inset)
            }
        }
        .padding(24)
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
}
