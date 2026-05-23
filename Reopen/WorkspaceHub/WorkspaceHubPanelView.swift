import SwiftUI

struct WorkspaceHubPanelView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 480, height: 620)
        .background(.regularMaterial)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.clockwise.circle.fill")
                .font(.title2)
                .foregroundColor(.accentColor)

            Text("Reopen")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .accessibilityLabel("Reopen")
    }
}
