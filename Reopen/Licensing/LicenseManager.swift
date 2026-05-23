import Foundation

enum LicenseTier: String, Codable, CaseIterable, Equatable, Sendable {
    case free
    case paid

    var title: String {
        switch self {
        case .free:
            return "Free"
        case .paid:
            return "Paid"
        }
    }
}

enum LicensedFeature: String, CaseIterable, Equatable, Sendable {
    case unlimitedWorkspaces
    case terminalCommands
    case codeProjects
    case windowRestore
    case importExport
}

struct LicenseEntitlement: Equatable, Sendable {
    var isAllowed: Bool
    var message: String?
}

struct LicenseManager: Sendable {
    static let freeWorkspaceLimit = 2

    func entitlement(
        for feature: LicensedFeature,
        tier: LicenseTier,
        workspaceCount: Int = 0
    ) -> LicenseEntitlement {
        switch tier {
        case .paid:
            return LicenseEntitlement(isAllowed: true, message: nil)
        case .free:
            switch feature {
            case .unlimitedWorkspaces:
                return LicenseEntitlement(
                    isAllowed: workspaceCount < Self.freeWorkspaceLimit,
                    message: "Free includes up to \(Self.freeWorkspaceLimit) workspaces."
                )
            case .terminalCommands:
                return LicenseEntitlement(isAllowed: false, message: "Terminal commands are part of Reopen Paid.")
            case .codeProjects:
                return LicenseEntitlement(isAllowed: false, message: "VS Code projects are part of Reopen Paid.")
            case .windowRestore:
                return LicenseEntitlement(isAllowed: false, message: "Best-effort window restore is part of Reopen Paid.")
            case .importExport:
                return LicenseEntitlement(isAllowed: false, message: "Import and export are part of Reopen Paid.")
            }
        }
    }

    func planSummary(for tier: LicenseTier) -> String {
        switch tier {
        case .free:
            return "Free: 2 workspaces, app/file/folder/URL launching."
        case .paid:
            return "Paid: unlimited workspaces, terminal commands, VS Code projects, window restore, and import/export."
        }
    }
}
