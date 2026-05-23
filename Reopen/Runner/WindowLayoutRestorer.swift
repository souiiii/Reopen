import Foundation

final class WindowLayoutRestorer {
    typealias RestoreLayouts = ([WindowLayout]) -> [ActionLaunchResult]

    private let restoreLayouts: RestoreLayouts

    init(windowManager: WindowManager = WindowManager()) {
        self.restoreLayouts = { layouts in
            windowManager.restore(layouts)
        }
    }

    init(restoreLayouts: @escaping RestoreLayouts) {
        self.restoreLayouts = restoreLayouts
    }

    func restore(_ layouts: [WindowLayout]) -> [ActionLaunchResult] {
        restoreLayouts(layouts)
    }

}
