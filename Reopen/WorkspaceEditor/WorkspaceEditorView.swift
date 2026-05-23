import SwiftUI

struct WorkspaceEditorView: View {
    @State private var draft: WorkspaceCreationDraft
    @State private var errorMessage: String?
    @State private var layoutMessage: String?

    let title: String
    let saveButtonTitle: String
    let onSave: (WorkspaceCreationDraft) throws -> Void
    let onCancel: () -> Void
    private let settings: AppSettings
    private let windowManager: WindowManager

    init(
        title: String,
        saveButtonTitle: String,
        draft: WorkspaceCreationDraft = WorkspaceCreationDraft(),
        settings: AppSettings = AppSettings(),
        windowManager: WindowManager = WindowManager(),
        onSave: @escaping (WorkspaceCreationDraft) throws -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.title = title
        self.saveButtonTitle = saveButtonTitle
        self._draft = State(initialValue: draft)
        self.settings = settings
        self.windowManager = windowManager
        self.onSave = onSave
        self.onCancel = onCancel
    }

    private var validationMessage: String? {
        draft.validationMessage
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)

                    workspaceDetailsSection
                    actionsSection
                    windowLayoutSection
                }
                .padding(24)
            }

            Divider()

            footer
        }
    }

    private var workspaceDetailsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Workspace Details")
                .font(.headline)

            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 12) {
                GridRow {
                    Text("Name")
                        .foregroundStyle(.secondary)
                    TextField("Coding", text: $draft.name)
                        .textFieldStyle(.roundedBorder)
                }

                GridRow {
                    Text("Icon")
                        .foregroundStyle(.secondary)
                    IconPicker(selection: $draft.icon)
                }

                GridRow {
                    Text("Color")
                        .foregroundStyle(.secondary)
                    WorkspaceColorPicker(selection: $draft.color)
                }

                GridRow {
                    Text("Description")
                        .foregroundStyle(.secondary)
                    TextField("Opens my development setup", text: $draft.description, axis: .vertical)
                        .lineLimit(2...4)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Actions")
                .font(.headline)

            actionButtons

            ActionListView(actions: $draft.actions)
        }
    }

    private var windowLayoutSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Best-effort Window Restore")
                .font(.headline)

            Toggle("Enable window restore", isOn: $draft.isWindowRestoreEnabled)

            HStack(spacing: 8) {
                Button {
                    saveCurrentWindowLayout()
                } label: {
                    Label("Save Current Layout", systemImage: "rectangle.on.rectangle")
                }
                .disabled(!draft.isWindowRestoreEnabled)

                if let layoutMessage {
                    Text(layoutMessage)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            if draft.windowLayouts.isEmpty {
                Text("No saved windows")
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach($draft.windowLayouts) { $layout in
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(layout.windowTitle?.isEmpty == false ? layout.windowTitle! : layout.appBundleIdentifier)
                                    .fontWeight(.medium)
                                Text(layout.appBundleIdentifier)
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }

                            Spacer()

                            Picker("Placement", selection: $layout.placement) {
                                ForEach(WindowPlacement.allCases, id: \.self) { placement in
                                    Text(placement.title).tag(placement)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 170)

                            Button(role: .destructive) {
                                draft.windowLayouts.removeAll { $0.id == layout.id }
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                            .help("Remove saved window")
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    private var actionButtons: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 166), spacing: 8)], alignment: .leading, spacing: 8) {
            Button {
                if let action = AppPicker.pickApplication() {
                    draft.actions.append(action)
                }
            } label: {
                Label("Add App", systemImage: "app")
            }

            Button {
                if let action = FilePicker.pickFile() {
                    draft.actions.append(action)
                }
            } label: {
                Label("Add File", systemImage: "doc")
            }

            Button {
                if let action = FolderPicker.pickFolderAction() {
                    draft.actions.append(action)
                }
            } label: {
                Label("Add Folder", systemImage: "folder")
            }

            Button {
                draft.actions.append(.url())
            } label: {
                Label("Add URL", systemImage: "link")
            }

            Button {
                draft.actions.append(.terminalCommand(
                    requiresConfirmation: settings.askBeforeRunningTerminalCommands
                ))
            } label: {
                Label("Add Terminal Command", systemImage: "terminal")
            }

            Button {
                if let folder = FolderPicker.pickFolder() {
                    draft.actions.append(.vsCodeProject(
                        path: folder.path,
                        editor: settings.preferredCodeEditor.rawValue
                    ))
                }
            } label: {
                Label("Add VS Code Project", systemImage: "chevron.left.forwardslash.chevron.right")
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .labelStyle(.titleAndIcon)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .lineLimit(2)
            } else if let validationMessage {
                Text(validationMessage)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Button("Cancel", action: onCancel)
                .keyboardShortcut(.cancelAction)

            Button(saveButtonTitle) {
                save()
            }
            .keyboardShortcut(.defaultAction)
            .disabled(validationMessage != nil)
        }
        .padding(16)
    }

    private func save() {
        do {
            try onSave(draft)
            onCancel()
        } catch let error as WorkspaceCreationError {
            errorMessage = error.userFacingMessage
        } catch let error as WorkspaceManagerError {
            errorMessage = error.userFacingMessage
        } catch let error as StorageError {
            errorMessage = error.userFacingMessage
        } catch {
            errorMessage = "Workspace could not be saved."
        }
    }

    private func saveCurrentWindowLayout() {
        do {
            let layouts = try windowManager.captureCurrentLayout(matching: draft.layoutCaptureBundleIdentifiers)
            draft.windowLayouts = layouts
            layoutMessage = "\(layouts.count) saved"
            errorMessage = nil
        } catch let error as WindowManagerError {
            layoutMessage = error.userFacingMessage
        } catch {
            layoutMessage = "Best-effort window layout could not be saved."
        }
    }
}
