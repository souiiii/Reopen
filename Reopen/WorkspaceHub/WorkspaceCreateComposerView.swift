import SwiftUI

struct WorkspaceCreateComposerView: View {
    private enum InlineActionInput: Equatable {
        case url
        case terminal
    }

    @Binding var draft: WorkspaceCreationDraft

    var title = "New Workspace"
    var systemImage = "plus.circle.fill"
    var saveButtonTitle = "Save"
    var showsCollapsedCard = true
    var showsWindowRestoreControls = false
    var layoutMessage: String?
    let isExpanded: Bool
    let validationMessage: String?
    let onExpand: () -> Void
    let onSave: () -> Void
    let onCancel: () -> Void
    var onCaptureWindowLayout: (() -> Void)?

    @State private var activeInput: InlineActionInput?
    @State private var pendingURL = "https://"
    @State private var pendingURLTitle = ""
    @State private var pendingCommandName = "Command"
    @State private var pendingCommand = ""
    @State private var pendingWorkingDirectory = ""
    @State private var pendingRequiresConfirmation = true
    @State private var editingActionID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isExpanded {
                expandedComposer
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else if showsCollapsedCard {
                Button(action: onExpand) {
                    HStack(spacing: 10) {
                        Image(systemName: systemImage)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.accentColor)

                        Text(title)
                            .font(.headline)
                            .fontWeight(.semibold)

                        Spacer()
                    }
                    .padding(14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .reopenCard(isSelected: isExpanded)
        .animation(.easeInOut(duration: 0.18), value: isExpanded)
    }

    private var expandedComposer: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.accentColor)

                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Button(action: onCancel) {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.reopenQuietIcon)
                .help("Cancel")
            }

            VStack(alignment: .leading, spacing: 8) {
                TextField("Workspace 1", text: $draft.name)
                    .textFieldStyle(.roundedBorder)

                TextField("Description", text: $draft.description, axis: .vertical)
                    .lineLimit(2...3)
                    .textFieldStyle(.roundedBorder)
            }

            actionArea

            if !draft.actions.isEmpty {
                actionList
            }

            if showsWindowRestoreControls {
                windowRestoreSection
            }

            if let validationMessage {
                Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }

            HStack(spacing: 8) {
                Spacer()

                Button(action: onCancel) {
                    Text("Cancel")
                }
                .buttonStyle(.reopenQuiet)

                Button(action: onSave) {
                    Label(saveButtonTitle, systemImage: "checkmark")
                }
                .buttonStyle(.reopenPrimary)
            }
        }
        .padding(14)
    }

    private var actionArea: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Actions")
                .reopenSectionTitle()

            actionButtons

            if let activeInput {
                Divider()

                switch activeInput {
                case .url:
                    urlInput
                case .terminal:
                    terminalInput
                }
            }
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: ReopenPanelMetrics.cornerRadius, style: .continuous)
                .fill(ReopenColor.quietFill)
        }
        .reopenSubtleBorder(opacity: 0.55)
    }

    private var windowRestoreSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Window Restore")
                .reopenSectionTitle()

            Toggle("Enable window restore", isOn: $draft.isWindowRestoreEnabled)
                .font(.caption)

            HStack(spacing: 8) {
                Button {
                    onCaptureWindowLayout?()
                } label: {
                    Label("Save Current Layout", systemImage: "rectangle.on.rectangle")
                }
                .buttonStyle(.reopenQuiet)
                .disabled(!draft.isWindowRestoreEnabled || onCaptureWindowLayout == nil)

                Text("Saved windows: \(draft.windowLayouts.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            }

            if let layoutMessage {
                Text(layoutMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: ReopenPanelMetrics.cornerRadius, style: .continuous)
                .fill(ReopenColor.quietFill)
        }
        .reopenSubtleBorder(opacity: 0.55)
    }

    private var actionButtons: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 6),
                GridItem(.flexible(), spacing: 6),
                GridItem(.flexible(), spacing: 6)
            ],
            alignment: .leading,
            spacing: 6
        ) {
            actionButton(title: "App", systemImage: "app") {
                if let action = AppPicker.pickApplication() {
                    draft.actions.append(action)
                    activeInput = nil
                }
            }

            actionButton(title: "File", systemImage: "doc") {
                if let action = FilePicker.pickFile() {
                    draft.actions.append(action)
                    activeInput = nil
                }
            }

            actionButton(title: "Folder", systemImage: "folder") {
                if let action = FolderPicker.pickFolderAction() {
                    draft.actions.append(action)
                    activeInput = nil
                }
            }

            actionButton(title: "URL", systemImage: "link") {
                activeInput = activeInput == .url ? nil : .url
            }

            actionButton(title: "Terminal", systemImage: "terminal") {
                activeInput = activeInput == .terminal ? nil : .terminal
            }

            actionButton(title: "VS Code", systemImage: "chevron.left.forwardslash.chevron.right") {
                if let folder = FolderPicker.pickFolder() {
                    draft.actions.append(.vsCodeProject(path: folder.path))
                    activeInput = nil
                }
            }
        }
    }

    private func actionButton(
        title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.reopenQuiet)
        .help(title)
    }

    private var urlInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("https://example.com", text: $pendingURL)
                .textFieldStyle(.roundedBorder)

            TextField("Display title", text: $pendingURLTitle)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 8) {
                Spacer()

                Button("Cancel") {
                    resetURLInput()
                    activeInput = nil
                }
                .buttonStyle(.reopenQuiet)

                Button {
                    draft.actions.append(WorkspaceActionDraft(
                        kind: .openURL,
                        url: pendingURL,
                        displayTitle: pendingURLTitle
                    ))
                    resetURLInput()
                    activeInput = nil
                } label: {
                    Label("Add URL", systemImage: "plus")
                }
                .buttonStyle(.reopenPrimary)
                .disabled(!canAddURL)
            }
        }
    }

    private var terminalInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Name", text: $pendingCommandName)
                .textFieldStyle(.roundedBorder)

            TextField("Command", text: $pendingCommand)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 6) {
                TextField("Working directory", text: $pendingWorkingDirectory)
                    .textFieldStyle(.roundedBorder)

                Button {
                    if let folder = FolderPicker.pickFolder() {
                        pendingWorkingDirectory = folder.path
                    }
                } label: {
                    Image(systemName: "folder")
                }
                .buttonStyle(.reopenQuietIcon)
                .help("Choose Folder")
            }

            Toggle("Ask before running", isOn: $pendingRequiresConfirmation)
                .font(.caption)

            HStack(spacing: 8) {
                Spacer()

                Button("Cancel") {
                    resetTerminalInput()
                    activeInput = nil
                }
                .buttonStyle(.reopenQuiet)

                Button {
                    draft.actions.append(WorkspaceActionDraft(
                        kind: .terminalCommand,
                        name: trimmed(pendingCommandName).isEmpty ? "Command" : pendingCommandName,
                        command: pendingCommand,
                        workingDirectory: pendingWorkingDirectory,
                        requiresConfirmation: pendingRequiresConfirmation
                    ))
                    resetTerminalInput()
                    activeInput = nil
                } label: {
                    Label("Add Command", systemImage: "plus")
                }
                .buttonStyle(.reopenPrimary)
                .disabled(!canAddTerminalCommand)
            }
        }
    }

    private var actionList: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach($draft.actions) { $action in
                actionRow(action: $action)
            }
        }
    }

    private func actionRow(action: Binding<WorkspaceActionDraft>) -> some View {
        let currentAction = action.wrappedValue

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 9) {
                Image(systemName: currentAction.kind.systemImageName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 18)

                Button {
                    toggleActionEditing(currentAction.id)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentAction.title)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .lineLimit(1)

                        if let detail = actionDetail(for: currentAction) {
                            Text(detail)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)

                if isEditableInline(currentAction.kind) {
                    Button {
                        toggleActionEditing(currentAction.id)
                    } label: {
                        Image(systemName: editingActionID == currentAction.id ? "chevron.up" : "pencil")
                    }
                    .buttonStyle(.reopenQuietIcon)
                    .help("Edit Action")
                }

                Button {
                    removeAction(id: currentAction.id)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.reopenQuietIcon)
                .foregroundStyle(.red)
                .help("Remove Action")

                Menu {
                    Button("Move Up") {
                        moveAction(id: currentAction.id, offset: -1)
                    }
                    .disabled(!canMoveAction(id: currentAction.id, offset: -1))

                    Button("Move Down") {
                        moveAction(id: currentAction.id, offset: 1)
                    }
                    .disabled(!canMoveAction(id: currentAction.id, offset: 1))
                } label: {
                    Image(systemName: "ellipsis")
                }
                .menuStyle(.borderlessButton)
                .frame(width: ReopenPanelMetrics.iconButtonSize, height: ReopenPanelMetrics.iconButtonSize)
                .help("More Actions")
            }

            if editingActionID == currentAction.id {
                inlineEditor(for: action)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background {
            RoundedRectangle(cornerRadius: ReopenPanelMetrics.cornerRadius, style: .continuous)
                .fill(ReopenColor.quietFill)
        }
        .reopenSubtleBorder(opacity: editingActionID == currentAction.id ? 0.9 : 0.55)
        .animation(.easeInOut(duration: 0.16), value: editingActionID)
    }

    @ViewBuilder
    private func inlineEditor(for action: Binding<WorkspaceActionDraft>) -> some View {
        switch action.wrappedValue.kind {
        case .openURL:
            urlActionEditor(action: action)
        case .terminalCommand:
            terminalActionEditor(action: action)
        case .openVSCodeProject:
            vsCodeActionEditor(action: action)
        default:
            EmptyView()
        }
    }

    private func urlActionEditor(action: Binding<WorkspaceActionDraft>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("URL", text: action.url)
                .textFieldStyle(.roundedBorder)

            TextField("Display title", text: action.displayTitle)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func terminalActionEditor(action: Binding<WorkspaceActionDraft>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("Name", text: action.name)
                .textFieldStyle(.roundedBorder)

            TextField("Command", text: action.command)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 6) {
                TextField("Working directory", text: action.workingDirectory)
                    .textFieldStyle(.roundedBorder)

                Button {
                    if let folder = FolderPicker.pickFolder() {
                        action.wrappedValue.workingDirectory = folder.path
                    }
                } label: {
                    Image(systemName: "folder")
                }
                .buttonStyle(.reopenQuietIcon)
                .help("Choose Folder")
            }

            Toggle("Ask before running", isOn: action.requiresConfirmation)
                .font(.caption)
        }
    }

    private func vsCodeActionEditor(action: Binding<WorkspaceActionDraft>) -> some View {
        HStack(spacing: 6) {
            TextField("Project folder", text: action.path)
                .textFieldStyle(.roundedBorder)

            Button {
                if let folder = FolderPicker.pickFolder() {
                    action.wrappedValue.path = folder.path
                }
            } label: {
                Image(systemName: "folder")
            }
            .buttonStyle(.reopenQuietIcon)
            .help("Choose Folder")
        }
    }

    private var canAddURL: Bool {
        let value = trimmed(pendingURL)
        return !value.isEmpty && value != "https://"
    }

    private var canAddTerminalCommand: Bool {
        !trimmed(pendingCommand).isEmpty && !trimmed(pendingWorkingDirectory).isEmpty
    }

    private func actionDetail(for action: WorkspaceActionDraft) -> String? {
        switch action.kind {
        case .openApp, .openFile, .openFolder, .openVSCodeProject:
            return action.path.isEmpty ? nil : action.path
        case .openURL:
            return action.url.isEmpty ? nil : action.url
        case .terminalCommand:
            return action.command.isEmpty ? action.workingDirectory : action.command
        case .shellScript:
            return action.scriptPath.isEmpty ? nil : action.scriptPath
        }
    }

    private func isEditableInline(_ kind: WorkspaceActionDraftKind) -> Bool {
        switch kind {
        case .openURL, .terminalCommand, .openVSCodeProject:
            return true
        default:
            return false
        }
    }

    private func toggleActionEditing(_ actionID: UUID) {
        editingActionID = editingActionID == actionID ? nil : actionID
    }

    private func removeAction(id actionID: UUID) {
        draft.actions.removeAll { $0.id == actionID }

        if editingActionID == actionID {
            editingActionID = nil
        }
    }

    private func moveAction(id actionID: UUID, offset: Int) {
        guard
            let currentIndex = draft.actions.firstIndex(where: { $0.id == actionID }),
            draft.actions.indices.contains(currentIndex + offset)
        else {
            return
        }

        draft.actions.swapAt(currentIndex, currentIndex + offset)
    }

    private func canMoveAction(id actionID: UUID, offset: Int) -> Bool {
        guard let currentIndex = draft.actions.firstIndex(where: { $0.id == actionID }) else {
            return false
        }

        return draft.actions.indices.contains(currentIndex + offset)
    }

    private func resetURLInput() {
        pendingURL = "https://"
        pendingURLTitle = ""
    }

    private func resetTerminalInput() {
        pendingCommandName = "Command"
        pendingCommand = ""
        pendingWorkingDirectory = ""
        pendingRequiresConfirmation = true
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
