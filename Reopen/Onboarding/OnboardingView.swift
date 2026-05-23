import SwiftUI

struct OnboardingView: View {
    let onCreateWorkspace: () -> Void
    let onOpenSettings: () -> Void
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome to Reopen")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Create a workspace, add what you use, then launch it from the menu bar.")
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Label("Start with apps, files, folders, and URLs.", systemImage: "checkmark.circle")
                Label("Add terminal commands, VS Code projects, and window restore when you need them.", systemImage: "checkmark.circle")
                Label("If macOS blocks something, Reopen will show what happened and how to fix it.", systemImage: "checkmark.circle")
            }
            .foregroundStyle(.secondary)

            HStack {
                Button("Settings", action: onOpenSettings)

                Spacer()

                Button("Later", action: onDone)

                Button("Create Workspace") {
                    onDone()
                    onCreateWorkspace()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(minWidth: 520, minHeight: 280)
    }
}
