import AppKit
import Foundation

final class AppLauncher {
    private let fileManager: FileManager
    private let openApplication: (URL) -> Bool

    init(
        fileManager: FileManager = .default,
        openApplication: @escaping (URL) -> Bool = { url in
            NSWorkspace.shared.open(url)
        }
    ) {
        self.fileManager = fileManager
        self.openApplication = openApplication
    }

    func launch(_ action: OpenAppAction) -> ActionLaunchResult {
        let appURL = URL(fileURLWithPath: action.path)
        let title = action.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? appURL.deletingPathExtension().lastPathComponent
            : action.name

        guard fileManager.fileExists(atPath: appURL.path) else {
            return ActionLaunchResult(
                actionID: action.id,
                actionType: WorkspaceActionType.openApp.rawValue,
                title: title,
                status: .failed,
                message: "App could not be found at \(action.path).",
                errorCode: "missing_app"
            )
        }

        guard appURL.pathExtension == "app" else {
            return ActionLaunchResult(
                actionID: action.id,
                actionType: WorkspaceActionType.openApp.rawValue,
                title: title,
                status: .failed,
                message: "Selected path is not a macOS app bundle.",
                errorCode: "invalid_app_path"
            )
        }

        guard openApplication(appURL) else {
            return ActionLaunchResult(
                actionID: action.id,
                actionType: WorkspaceActionType.openApp.rawValue,
                title: title,
                status: .failed,
                message: "macOS could not open \(title).",
                errorCode: "app_launch_failed"
            )
        }

        return ActionLaunchResult(
            actionID: action.id,
            actionType: WorkspaceActionType.openApp.rawValue,
            title: title,
            status: .succeeded,
            message: "Opened \(title)."
        )
    }
}
