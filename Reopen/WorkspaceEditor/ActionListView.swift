import SwiftUI

struct ActionListView: View {
    @Binding var actions: [WorkspaceActionDraft]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if actions.isEmpty {
                Text("No actions yet.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                ForEach($actions) { $action in
                    ActionEditorView(
                        action: $action,
                        onDelete: {
                            actions.removeAll { $0.id == action.id }
                        }
                    )
                }
            }
        }
    }
}
