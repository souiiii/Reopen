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
                    let index = actions.firstIndex { $0.id == action.id } ?? 0
                    ActionEditorView(
                        action: $action,
                        canMoveUp: index > 0,
                        canMoveDown: index < actions.count - 1,
                        onMoveUp: {
                            moveAction(id: action.id, offset: -1)
                        },
                        onMoveDown: {
                            moveAction(id: action.id, offset: 1)
                        },
                        onDelete: {
                            actions.removeAll { $0.id == action.id }
                        }
                    )
                }
            }
        }
    }

    private func moveAction(id: UUID, offset: Int) {
        guard
            let currentIndex = actions.firstIndex(where: { $0.id == id }),
            actions.indices.contains(currentIndex + offset)
        else {
            return
        }

        actions.swapAt(currentIndex, currentIndex + offset)
    }
}
