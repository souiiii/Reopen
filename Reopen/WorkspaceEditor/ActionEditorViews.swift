import SwiftUI

struct ActionEditorView: View {
    @Binding var action: WorkspaceActionDraft
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(action.kind.title, systemImage: action.kind.systemImageName)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Button(action: onMoveUp) {
                    Image(systemName: "arrow.up")
                }
                .buttonStyle(.borderless)
                .disabled(!canMoveUp)
                .help("Move action up")

                Button(action: onMoveDown) {
                    Image(systemName: "arrow.down")
                }
                .buttonStyle(.borderless)
                .disabled(!canMoveDown)
                .help("Move action down")

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .help("Remove action")
            }

            fields
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var fields: some View {
        switch action.kind {
        case .openApp, .openFile, .openFolder:
            pathBackedFields
        case .openURL:
            urlFields
        case .terminalCommand:
            terminalFields
        case .openVSCodeProject:
            projectFields
        case .shellScript:
            shellScriptFields
        }
    }

    private var pathBackedFields: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Name", text: $action.name)
                .textFieldStyle(.roundedBorder)
            TextField("Path", text: $action.path)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var urlFields: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("URL", text: $action.url)
                .textFieldStyle(.roundedBorder)
            TextField("Display title", text: $action.displayTitle)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var terminalFields: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Name", text: $action.name)
                .textFieldStyle(.roundedBorder)
            TextField("Command", text: $action.command)
                .textFieldStyle(.roundedBorder)
            HStack {
                TextField("Working directory", text: $action.workingDirectory)
                    .textFieldStyle(.roundedBorder)
                Button("Choose") {
                    if let folder = FolderPicker.pickFolder() {
                        action.workingDirectory = folder.path
                    }
                }
            }
            Toggle("Ask before running", isOn: $action.requiresConfirmation)
        }
    }

    private var projectFields: some View {
        HStack {
            TextField("Project folder", text: $action.path)
                .textFieldStyle(.roundedBorder)
            Button("Choose") {
                if let folder = FolderPicker.pickFolder() {
                    action.path = folder.path
                }
            }
        }
    }

    private var shellScriptFields: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Name", text: $action.name)
                .textFieldStyle(.roundedBorder)
            TextField("Script path", text: $action.scriptPath)
                .textFieldStyle(.roundedBorder)
            TextField("Working directory", text: $action.workingDirectory)
                .textFieldStyle(.roundedBorder)
        }
    }
}
