import AppKit
import ApplicationServices
import Foundation

struct AccessibleWindowSnapshot: Equatable, Sendable {
    var appBundleIdentifier: String
    var appName: String
    var windowTitle: String?
    var screenIdentifier: String?
    var frame: WindowFrame
}

enum AccessibilityWindowServiceError: Error, Equatable {
    case accessibilityPermissionMissing
    case appNotRunning(String)
    case windowNotFound(String)
    case windowMoveFailed(String)
}

final class AccessibilityWindowService: @unchecked Sendable {
    private let isTrusted: @Sendable () -> Bool
    private let runningApplicationsProvider: @Sendable () -> [NSRunningApplication]

    init(
        isTrusted: @escaping @Sendable () -> Bool = {
            AXIsProcessTrusted()
        },
        runningApplicationsProvider: @escaping @Sendable () -> [NSRunningApplication] = {
            NSWorkspace.shared.runningApplications
        }
    ) {
        self.isTrusted = isTrusted
        self.runningApplicationsProvider = runningApplicationsProvider
    }

    func captureOpenWindows(matching bundleIdentifiers: Set<String>? = nil) throws -> [AccessibleWindowSnapshot] {
        guard isTrusted() else {
            throw AccessibilityWindowServiceError.accessibilityPermissionMissing
        }

        var snapshots: [AccessibleWindowSnapshot] = []

        for application in runningApplicationsProvider() {
            guard
                let bundleIdentifier = application.bundleIdentifier,
                bundleIdentifiers?.contains(bundleIdentifier) ?? true
            else {
                continue
            }

            snapshots.append(contentsOf: captureWindows(for: application, bundleIdentifier: bundleIdentifier))
        }

        return snapshots
    }

    func restore(_ layout: WindowLayout, to frame: WindowFrame) throws {
        guard isTrusted() else {
            throw AccessibilityWindowServiceError.accessibilityPermissionMissing
        }

        guard let application = runningApplicationsProvider().first(where: { application in
            application.bundleIdentifier == layout.appBundleIdentifier
        }) else {
            throw AccessibilityWindowServiceError.appNotRunning(layout.appBundleIdentifier)
        }

        let windows = windowElements(for: application)
        guard let window = bestMatchingWindow(in: windows, layout: layout) else {
            throw AccessibilityWindowServiceError.windowNotFound(layout.windowTitle ?? layout.appBundleIdentifier)
        }

        guard setFrame(frame, for: window) else {
            throw AccessibilityWindowServiceError.windowMoveFailed(layout.windowTitle ?? layout.appBundleIdentifier)
        }
    }

    private func captureWindows(for application: NSRunningApplication, bundleIdentifier: String) -> [AccessibleWindowSnapshot] {
        windowElements(for: application).compactMap { window in
            guard let frame = frame(for: window), frame.width > 0, frame.height > 0 else {
                return nil
            }

            return AccessibleWindowSnapshot(
                appBundleIdentifier: bundleIdentifier,
                appName: application.localizedName ?? bundleIdentifier,
                windowTitle: stringAttribute(kAXTitleAttribute, from: window),
                screenIdentifier: NSScreen.bestEffortIdentifier(containing: frame),
                frame: frame
            )
        }
    }

    private func windowElements(for application: NSRunningApplication) -> [AXUIElement] {
        let appElement = AXUIElementCreateApplication(application.processIdentifier)
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &value) == .success else {
            return []
        }

        return (value as? [AXUIElement]) ?? []
    }

    private func bestMatchingWindow(in windows: [AXUIElement], layout: WindowLayout) -> AXUIElement? {
        if let title = layout.windowTitle, !title.isEmpty {
            return windows.first { window in
                stringAttribute(kAXTitleAttribute, from: window) == title
            } ?? windows.first
        }

        return windows.first
    }

    private func frame(for window: AXUIElement) -> WindowFrame? {
        var positionValue: CFTypeRef?
        var sizeValue: CFTypeRef?
        guard
            AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue) == .success,
            AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue) == .success,
            let positionValue,
            let sizeValue
        else {
            return nil
        }

        let positionAXValue = positionValue as! AXValue
        let sizeAXValue = sizeValue as! AXValue

        var position = CGPoint.zero
        var size = CGSize.zero
        guard
            AXValueGetValue(positionAXValue, .cgPoint, &position),
            AXValueGetValue(sizeAXValue, .cgSize, &size)
        else {
            return nil
        }

        return WindowFrame(x: position.x, y: position.y, width: size.width, height: size.height)
    }

    private func setFrame(_ frame: WindowFrame, for window: AXUIElement) -> Bool {
        var position = CGPoint(x: frame.x, y: frame.y)
        var size = CGSize(width: frame.width, height: frame.height)

        guard
            let positionValue = AXValueCreate(.cgPoint, &position),
            let sizeValue = AXValueCreate(.cgSize, &size)
        else {
            return false
        }

        let positionStatus = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
        let sizeStatus = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)

        return positionStatus == .success && sizeStatus == .success
    }

    private func stringAttribute(_ attribute: String, from element: AXUIElement) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else {
            return nil
        }

        return value as? String
    }
}

private extension NSScreen {
    static func bestEffortIdentifier(containing frame: WindowFrame) -> String? {
        let center = CGPoint(x: frame.centerX, y: frame.centerY)
        return screens.first { screen in
            screen.frame.contains(center)
        }?.bestEffortIdentifier ?? main?.bestEffortIdentifier
    }

    var bestEffortIdentifier: String {
        localizedName
    }
}
