import SwiftUI

struct MenuBarView: View {
    let workspaceNames: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(MenuBarCommands.appTitle)
                .font(.headline)

            if workspaceNames.isEmpty {
                Text(MenuBarCommands.noWorkspacesTitle)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(workspaceNames, id: \.self) { workspaceName in
                    Text(workspaceName)
                }
            }
        }
        .padding()
    }
}
