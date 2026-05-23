import Foundation

enum WindowManagerError: Error, Equatable {
    case accessibilityPermissionMissing
    case noSupportedWindows

    var userFacingMessage: String {
        switch self {
        case .accessibilityPermissionMissing:
            return PermissionKind.accessibility.explanation
        case .noSupportedWindows:
            return "No supported windows were found for best-effort window restore."
        }
    }
}

final class WindowManager {
    typealias CaptureWindows = @Sendable (Set<String>?) throws -> [AccessibleWindowSnapshot]
    typealias RestoreWindow = @Sendable (WindowLayout, WindowFrame) throws -> Void
    typealias ScreenProvider = @Sendable () -> [WindowScreen]

    private let captureWindows: CaptureWindows
    private let restoreWindow: RestoreWindow
    private let screenProvider: ScreenProvider
    private let layoutCalculator: WindowLayoutCalculator

    init(
        accessibilityWindowService: AccessibilityWindowService = AccessibilityWindowService(),
        layoutCalculator: WindowLayoutCalculator = WindowLayoutCalculator(),
        screenProvider: @escaping ScreenProvider = {
            WindowLayoutCalculator.currentScreens()
        }
    ) {
        self.captureWindows = { bundleIdentifiers in
            try accessibilityWindowService.captureOpenWindows(matching: bundleIdentifiers)
        }
        self.restoreWindow = { layout, frame in
            try accessibilityWindowService.restore(layout, to: frame)
        }
        self.screenProvider = screenProvider
        self.layoutCalculator = layoutCalculator
    }

    init(
        captureWindows: @escaping CaptureWindows,
        restoreWindow: @escaping RestoreWindow,
        screenProvider: @escaping ScreenProvider,
        layoutCalculator: WindowLayoutCalculator = WindowLayoutCalculator()
    ) {
        self.captureWindows = captureWindows
        self.restoreWindow = restoreWindow
        self.screenProvider = screenProvider
        self.layoutCalculator = layoutCalculator
    }

    func captureCurrentLayout(matching bundleIdentifiers: Set<String>? = nil) throws -> [WindowLayout] {
        do {
            let snapshots = try captureWindows(bundleIdentifiers)
            let layouts = snapshots.map { snapshot in
                WindowLayout(
                    appBundleIdentifier: snapshot.appBundleIdentifier,
                    windowTitle: snapshot.windowTitle,
                    screenIdentifier: snapshot.screenIdentifier,
                    placement: .customRectangle,
                    x: snapshot.frame.x,
                    y: snapshot.frame.y,
                    width: snapshot.frame.width,
                    height: snapshot.frame.height
                )
            }

            guard !layouts.isEmpty else {
                throw WindowManagerError.noSupportedWindows
            }

            return layouts
        } catch AccessibilityWindowServiceError.accessibilityPermissionMissing {
            throw WindowManagerError.accessibilityPermissionMissing
        }
    }

    func restore(_ layouts: [WindowLayout]) -> [ActionLaunchResult] {
        let screens = screenProvider()

        return layouts.map { layout in
            let frame = layoutCalculator.targetFrame(for: layout, screens: screens)

            do {
                try restoreWindow(layout, frame)
                return ActionLaunchResult(
                    actionID: layout.id,
                    actionType: "windowLayout",
                    title: title(for: layout),
                    status: .succeeded,
                    message: "Best-effort window restore applied."
                )
            } catch {
                return ActionLaunchResult(
                    actionID: layout.id,
                    actionType: "windowLayout",
                    title: title(for: layout),
                    status: .failed,
                    message: failureMessage(for: error),
                    errorCode: failureCode(for: error)
                )
            }
        }
    }

    private func title(for layout: WindowLayout) -> String {
        layout.windowTitle?.isEmpty == false ? layout.windowTitle! : layout.appBundleIdentifier
    }

    private func failureMessage(for error: Error) -> String {
        switch error {
        case AccessibilityWindowServiceError.accessibilityPermissionMissing:
            return PermissionKind.accessibility.explanation
        case AccessibilityWindowServiceError.appNotRunning(let bundleIdentifier):
            return "Best-effort window restore skipped because \(bundleIdentifier) is not running."
        case AccessibilityWindowServiceError.windowNotFound(let title):
            return "Best-effort window restore could not find \(title)."
        case AccessibilityWindowServiceError.windowMoveFailed(let title):
            return "Best-effort window restore could not move \(title)."
        default:
            return "Best-effort window restore failed."
        }
    }

    private func failureCode(for error: Error) -> String {
        switch error {
        case AccessibilityWindowServiceError.accessibilityPermissionMissing:
            return "permission_accessibility_missing"
        case AccessibilityWindowServiceError.appNotRunning:
            return "window_app_not_running"
        case AccessibilityWindowServiceError.windowNotFound:
            return "window_not_found"
        case AccessibilityWindowServiceError.windowMoveFailed:
            return "window_move_failed"
        default:
            return "window_layout_failed"
        }
    }
}
