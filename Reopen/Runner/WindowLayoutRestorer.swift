import Foundation

final class WindowLayoutRestorer {
    typealias RestoreLayouts = ([WindowLayout]) -> [ActionLaunchResult]

    private let restoreLayouts: RestoreLayouts

    init(restoreLayouts: @escaping RestoreLayouts = WindowLayoutRestorer.defaultRestore) {
        self.restoreLayouts = restoreLayouts
    }

    func restore(_ layouts: [WindowLayout]) -> [ActionLaunchResult] {
        restoreLayouts(layouts)
    }

    private static func defaultRestore(_ layouts: [WindowLayout]) -> [ActionLaunchResult] {
        layouts.map { layout in
            ActionLaunchResult(
                actionID: layout.id,
                actionType: "windowLayout",
                title: layout.windowTitle ?? layout.appBundleIdentifier,
                status: .skipped,
                message: "Window layout restore will be implemented in Phase 17.",
                errorCode: "window_layout_pending"
            )
        }
    }
}
