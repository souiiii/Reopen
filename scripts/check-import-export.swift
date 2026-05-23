import Foundation

enum ImportExportCheckFailure: Error, CustomStringConvertible {
    case message(String)

    var description: String {
        switch self {
        case .message(let message):
            return message
        }
    }
}

func check(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() {
        throw ImportExportCheckFailure.message(message)
    }
}

@MainActor
@main
enum ImportExportChecks {
    static func main() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ReopenImportExportChecks-\(UUID().uuidString)", isDirectory: true)

        defer {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }

        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)

        let importExportManager = WorkspaceImportExportManager()

        try exportAllAndIndividualWorkspaces(
            manager: importExportManager,
            temporaryDirectory: temporaryDirectory
        )
        try importSingleWorkspaceJSON(
            manager: importExportManager,
            temporaryDirectory: temporaryDirectory
        )
        try duplicateWorkspaceIDsAreRegenerated(
            manager: importExportManager,
            temporaryDirectory: temporaryDirectory
        )
        try invalidAndUnsafeImportsAreRejected(
            manager: importExportManager,
            temporaryDirectory: temporaryDirectory
        )
        try settingsManagerShowsImportSummary(temporaryDirectory: temporaryDirectory)

        print("Import/export checks passed.")
    }

    private static func sampleWorkspace(id: UUID = UUID(), name: String) -> Workspace {
        Workspace(
            id: id,
            name: name,
            actions: [
                .openURL(OpenURLAction(url: "https://example.com", displayTitle: "Example"))
            ],
            createdAt: Date(timeIntervalSinceReferenceDate: 100),
            updatedAt: Date(timeIntervalSinceReferenceDate: 200)
        )
    }

    private static func exportAllAndIndividualWorkspaces(
        manager: WorkspaceImportExportManager,
        temporaryDirectory: URL
    ) throws {
        let first = sampleWorkspace(name: "Coding")
        let second = sampleWorkspace(name: "Writing")
        let allURL = temporaryDirectory.appendingPathComponent("all-workspaces.json", isDirectory: false)
        let oneURL = temporaryDirectory.appendingPathComponent("one-workspace.json", isDirectory: false)

        try manager.exportWorkspaces([first, second], to: allURL)
        try manager.exportWorkspace(first, to: oneURL)

        let allResult = try manager.importWorkspaces(from: allURL)
        let oneResult = try manager.importWorkspaces(from: oneURL)

        try check(allResult.workspaces == [first, second], "Exported all-workspace JSON should import all workspaces.")
        try check(oneResult.workspaces == [first], "Exported individual workspace JSON should import one workspace.")
    }

    private static func importSingleWorkspaceJSON(
        manager: WorkspaceImportExportManager,
        temporaryDirectory: URL
    ) throws {
        let workspace = sampleWorkspace(name: "Solo")
        let url = temporaryDirectory.appendingPathComponent("single-workspace-object.json", isDirectory: false)

        try JSONEncoder().encode(workspace).write(to: url, options: [.atomic])
        let result = try manager.importWorkspaces(from: url)

        try check(result.workspaces == [workspace], "Import should accept a single workspace JSON object.")
        try check(result.summary.summaryText.contains("Solo"), "Import summary should name the imported workspace.")
    }

    private static func duplicateWorkspaceIDsAreRegenerated(
        manager: WorkspaceImportExportManager,
        temporaryDirectory: URL
    ) throws {
        let duplicatedID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let existing = sampleWorkspace(id: duplicatedID, name: "Existing")
        let duplicateA = sampleWorkspace(id: duplicatedID, name: "Duplicate A")
        let duplicateB = sampleWorkspace(id: duplicatedID, name: "Duplicate B")
        let url = temporaryDirectory.appendingPathComponent("duplicate-ids.json", isDirectory: false)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(WorkspaceStorageEnvelope(workspaces: [duplicateA, duplicateB]))
            .write(to: url, options: [.atomic])
        let result = try manager.importWorkspaces(from: url, existingWorkspaces: [existing])
        let importedIDs = result.workspaces.map(\.id)

        try check(result.workspaces.count == 2, "Both duplicate-ID workspaces should still import.")
        try check(!importedIDs.contains(duplicatedID), "Imported IDs that collide with existing workspaces should be regenerated.")
        try check(Set(importedIDs).count == importedIDs.count, "Regenerated imported IDs should be unique.")
        try check(result.summary.regeneratedIDCount == 2, "Import summary should count regenerated duplicate IDs.")
    }

    private static func invalidAndUnsafeImportsAreRejected(
        manager: WorkspaceImportExportManager,
        temporaryDirectory: URL
    ) throws {
        let invalidURL = temporaryDirectory.appendingPathComponent("invalid.json", isDirectory: false)
        let unsafeURL = temporaryDirectory.appendingPathComponent("workspace.txt", isDirectory: false)

        try Data("{not valid json".utf8).write(to: invalidURL, options: [.atomic])
        try Data("{}".utf8).write(to: unsafeURL, options: [.atomic])

        do {
            _ = try manager.importWorkspaces(from: invalidURL)
            throw ImportExportCheckFailure.message("Invalid JSON should be rejected.")
        } catch WorkspaceImportExportError.invalidWorkspaceData {
        } catch {
            throw ImportExportCheckFailure.message("Expected invalidWorkspaceData, got \(error).")
        }

        do {
            _ = try manager.importWorkspaces(from: unsafeURL)
            throw ImportExportCheckFailure.message("Unsafe non-JSON imports should be rejected.")
        } catch WorkspaceImportExportError.unsafeImportFile {
        } catch {
            throw ImportExportCheckFailure.message("Expected unsafeImportFile, got \(error).")
        }
    }

    private static func settingsManagerShowsImportSummary(temporaryDirectory: URL) throws {
        let storageManager = StorageManager(applicationSupportDirectory: temporaryDirectory.appendingPathComponent("settings-manager", isDirectory: true))
        let backupManager = JSONBackupManager(storageManager: storageManager)
        let settingsStore = SettingsStore(storageManager: storageManager, backupManager: backupManager)
        let workspaceStore = WorkspaceStore(
            storageManager: storageManager,
            migrationManager: MigrationManager(),
            backupManager: backupManager
        )
        let workspaceManager = WorkspaceManager(workspaceStore: workspaceStore)
        let settingsManager = SettingsManager(
            settings: AppSettings(),
            settingsStore: settingsStore,
            runtime: SettingsRuntime(settings: AppSettings()),
            launchAtLoginService: RecordingLaunchAtLoginService(),
            dockIconService: RecordingDockIconService()
        )
        let existing = sampleWorkspace(name: "Existing")
        let imported = sampleWorkspace(id: existing.id, name: "Imported Copy")
        let url = temporaryDirectory.appendingPathComponent("settings-import.json", isDirectory: false)

        _ = try workspaceManager.createWorkspace(existing)
        try WorkspaceImportExportManager().exportWorkspace(imported, to: url)

        settingsManager.importWorkspaces(from: url, into: workspaceManager, confirmed: true)

        try check(workspaceManager.getAllWorkspaces().count == 2, "Settings import should add imported workspaces.")
        try check(settingsManager.lastImportSummary?.importedCount == 1, "Settings import should publish an import summary.")
        try check(settingsManager.lastImportSummary?.regeneratedIDCount == 1, "Settings import summary should mention regenerated duplicate IDs.")
        try check(settingsManager.statusMessage?.contains("Imported Copy") == true, "Settings status should clearly show what was added.")
    }
}

@MainActor
private final class RecordingLaunchAtLoginService: LaunchAtLoginManaging {
    func setLaunchAtLoginEnabled(_ enabled: Bool) throws {}
}

@MainActor
private final class RecordingDockIconService: DockIconManaging {
    func setDockIconVisible(_ visible: Bool) {}
}
