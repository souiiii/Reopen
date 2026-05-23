import Foundation

struct ActionFailureGuidance: Equatable, Sendable {
    var whatFailed: String
    var whyItMayHaveFailed: String
    var howToFix: String
}

enum ActionFailureGuidanceProvider {
    static func guidance(for result: ActionLaunchResult) -> ActionFailureGuidance? {
        guard result.status != .succeeded else {
            return nil
        }

        switch result.errorCode {
        case "missing_app":
            return ActionFailureGuidance(
                whatFailed: "\(result.title) could not open.",
                whyItMayHaveFailed: "The saved app may have been moved, deleted, or renamed.",
                howToFix: "Edit the workspace and choose the app again."
            )
        case "invalid_app_path", "app_launch_failed":
            return ActionFailureGuidance(
                whatFailed: "\(result.title) could not open as an app.",
                whyItMayHaveFailed: "The saved path may not point to a valid macOS app, or macOS refused to open it.",
                howToFix: "Choose a valid .app file, then run the workspace again."
            )
        case "missing_file":
            return ActionFailureGuidance(
                whatFailed: "\(result.title) could not open.",
                whyItMayHaveFailed: "The saved file may have been moved, deleted, or blocked by macOS file access.",
                howToFix: "Use Repair or edit the workspace and choose the file again."
            )
        case "missing_folder":
            return ActionFailureGuidance(
                whatFailed: "\(result.title) could not open.",
                whyItMayHaveFailed: "The saved folder may have been moved, deleted, or blocked by macOS file access.",
                howToFix: "Use Repair or edit the workspace and choose the folder again."
            )
        case "invalid_file_path", "invalid_folder_path", "file_open_failed", "folder_open_failed":
            return ActionFailureGuidance(
                whatFailed: "\(result.title) could not open.",
                whyItMayHaveFailed: "The saved path no longer matches the expected file or folder type.",
                howToFix: "Edit the workspace and replace this item with the correct file or folder."
            )
        case "invalid_url", "url_open_failed":
            return ActionFailureGuidance(
                whatFailed: "\(result.title) could not open.",
                whyItMayHaveFailed: "The URL may be incomplete, unsupported, or blocked by the default browser.",
                howToFix: "Edit the workspace and use a full web address such as https://example.com."
            )
        case "missing_working_directory", "empty_terminal_command", "terminal_command_failed", "terminal_command_cancelled":
            return ActionFailureGuidance(
                whatFailed: "\(result.title) did not run.",
                whyItMayHaveFailed: "The command, working directory, or Terminal automation step was not available.",
                howToFix: "Check the command and working directory. If macOS asks for Automation permission, allow Reopen to control Terminal."
            )
        case "permission_automation_missing", "permission_automation_denied":
            return ActionFailureGuidance(
                whatFailed: "\(result.title) was skipped.",
                whyItMayHaveFailed: "macOS has not allowed Reopen to control Terminal.",
                howToFix: "Open System Settings and allow Automation access, then run the workspace again."
            )
        case "permission_accessibility_missing":
            return ActionFailureGuidance(
                whatFailed: "\(result.title) was skipped.",
                whyItMayHaveFailed: "macOS Accessibility access is required to move or resize windows.",
                howToFix: "Open System Settings and allow Accessibility access for Reopen."
            )
        case "permission_file_access_missing":
            return ActionFailureGuidance(
                whatFailed: "\(result.title) needs file access.",
                whyItMayHaveFailed: "macOS no longer trusts the saved file or folder permission.",
                howToFix: "Use Repair to choose the file or folder again."
            )
        case "missing_code_project", "invalid_code_project_path", "missing_vscode", "code_command_failed", "vscode_open_failed":
            return ActionFailureGuidance(
                whatFailed: "\(result.title) could not open in the code editor.",
                whyItMayHaveFailed: "The project folder or preferred editor may be missing.",
                howToFix: "Check the project folder and install VS Code or update the preferred editor in Settings."
            )
        case "window_app_not_running", "window_not_found", "window_move_failed", "window_layout_failed":
            return ActionFailureGuidance(
                whatFailed: "\(result.title) could not be restored.",
                whyItMayHaveFailed: "The app may not expose that window to macOS, or the window may be minimized, fullscreen, or unavailable.",
                howToFix: "Open the app window, save the layout again, or leave window restore disabled for that workspace."
            )
        case "workspace_validation_failed":
            return ActionFailureGuidance(
                whatFailed: "Workspace validation failed.",
                whyItMayHaveFailed: "The workspace is missing required information.",
                howToFix: "Edit the workspace and complete any missing fields."
            )
        default:
            guard result.status == .failed else {
                return nil
            }

            return ActionFailureGuidance(
                whatFailed: "\(result.title) failed.",
                whyItMayHaveFailed: "macOS or the saved workspace data could not complete this action.",
                howToFix: "Edit the workspace, check the saved item, then try again."
            )
        }
    }
}
