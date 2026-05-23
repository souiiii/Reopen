import Foundation

enum PermissionStatus: Equatable, Sendable {
    case granted
    case denied
    case notDetermined
    case unknown

    var isGranted: Bool {
        self == .granted
    }
}

enum PermissionKind: String, CaseIterable, Equatable, Sendable {
    case accessibility
    case automation
    case fileAccess

    var title: String {
        switch self {
        case .accessibility:
            return "Accessibility Permission"
        case .automation:
            return "Automation Permission"
        case .fileAccess:
            return "File Access"
        }
    }

    var explanation: String {
        switch self {
        case .accessibility:
            return "Reopen needs Accessibility permission to restore window positions. You can still launch apps, files, folders, URLs, VS Code projects, and terminal commands without it."
        case .automation:
            return "Reopen needs Automation permission to control Terminal.app for terminal commands. Other workspace actions can still run without it."
        case .fileAccess:
            return "Reopen needs saved file access to reopen selected files and folders reliably. Choose the item again to refresh access."
        }
    }

    var settingsURL: URL? {
        switch self {
        case .accessibility:
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        case .automation:
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")
        case .fileAccess:
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_FilesAndFolders")
        }
    }

    static func kind(for errorCode: String?) -> PermissionKind? {
        switch errorCode {
        case "permission_accessibility_missing":
            return .accessibility
        case "permission_automation_denied", "permission_automation_missing":
            return .automation
        case "permission_file_access_missing":
            return .fileAccess
        default:
            return nil
        }
    }
}
