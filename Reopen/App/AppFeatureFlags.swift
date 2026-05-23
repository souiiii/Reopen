import Foundation

struct AppFeatureFlags: Equatable, Sendable {
    var useUnifiedWorkspacePanel: Bool

    static let current = AppFeatureFlags(
        useUnifiedWorkspacePanel: defaultUseUnifiedWorkspacePanel
    )

    private static var defaultUseUnifiedWorkspacePanel: Bool {
        #if REOPEN_USE_LEGACY_MENU_BAR
        false
        #else
        true
        #endif
    }
}
