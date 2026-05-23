import SwiftUI

struct WorkspaceHubFooterView: View {
    let onOpenSettings: () -> Void
    let onQuit: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onOpenSettings) {
                Label("Settings", systemImage: "gearshape")
            }
            .buttonStyle(.reopenQuiet)
            .help("Settings")

            Spacer()

            secondaryUtilitiesMenu

            Button(action: onQuit) {
                Label("Quit", systemImage: "power")
            }
            .buttonStyle(.reopenQuiet)
            .help("Quit Reopen")
        }
        .padding(.horizontal, ReopenPanelMetrics.horizontalPadding)
        .padding(.vertical, 12)
    }

    private var secondaryUtilitiesMenu: some View {
        Menu {
            Button(action: onOpenSettings) {
                Label("Data & Import/Export", systemImage: "externaldrive")
            }

            Button(action: onOpenSettings) {
                Label("License", systemImage: "key")
            }

            Button(action: onOpenSettings) {
                Label("Privacy & Logs", systemImage: "doc.text.magnifyingglass")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .menuStyle(.borderlessButton)
        .frame(width: ReopenPanelMetrics.iconButtonSize, height: ReopenPanelMetrics.iconButtonSize)
        .help("More")
    }
}
