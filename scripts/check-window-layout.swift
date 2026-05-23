import Foundation

enum WindowLayoutCheckFailure: Error, CustomStringConvertible {
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
        throw WindowLayoutCheckFailure.message(message)
    }
}

@main
enum WindowLayoutChecks {
    private final class Recorder: @unchecked Sendable {
        var restored: [(WindowLayout, WindowFrame)] = []
        var restoreError: Error?
    }

    static func main() throws {
        try oldLayoutDefaultsToCustomRectangle()
        try workspaceRestoreFlagDefaultsAndPersists()
        try draftPreservesWindowRestoreSettings()
        try currentLayoutCaptureStoresWindowMetadata()
        try placementCalculatorSupportsV1Options()
        try restoreUsesCalculatedFrame()
        try unsupportedWindowsReportFailures()
        try disabledWindowRestoreSkipsLayouts()

        print("Window layout checks passed.")
    }

    private static func oldLayoutDefaultsToCustomRectangle() throws {
        let json = """
        {
          "id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
          "appBundleIdentifier": "com.example.App",
          "x": 20,
          "y": 30,
          "width": 640,
          "height": 480
        }
        """

        let layout = try JSONDecoder().decode(WindowLayout.self, from: Data(json.utf8))

        try check(layout.placement == .customRectangle, "Old layouts should default to customRectangle placement.")
    }

    private static func workspaceRestoreFlagDefaultsAndPersists() throws {
        let legacyJSON = """
        {
          "id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
          "name": "Legacy",
          "actions": [],
          "windowLayouts": [],
          "createdAt": 0,
          "updatedAt": 0
        }
        """
        let decodedLegacy = try JSONDecoder().decode(Workspace.self, from: Data(legacyJSON.utf8))
        let workspace = Workspace(name: "No Restore", isWindowRestoreEnabled: false)
        let roundTripped = try JSONDecoder().decode(Workspace.self, from: JSONEncoder().encode(workspace))

        try check(decodedLegacy.isWindowRestoreEnabled, "Legacy workspaces should default window restore to enabled.")
        try check(!roundTripped.isWindowRestoreEnabled, "Window restore disabled flag should persist through JSON.")
    }

    private static func draftPreservesWindowRestoreSettings() throws {
        let layout = WindowLayout(
            appBundleIdentifier: "com.example.App",
            placement: .leftHalf,
            x: 0,
            y: 0,
            width: 400,
            height: 800
        )
        let workspace = Workspace(
            name: "Layout",
            windowLayouts: [layout],
            isWindowRestoreEnabled: false
        )
        let draft = WorkspaceCreationDraft(workspace: workspace)
        let remadeWorkspace = try draft.makeWorkspace()

        try check(!draft.isWindowRestoreEnabled, "Draft should preserve disabled window restore.")
        try check(draft.windowLayouts.first?.placement == .leftHalf, "Draft should preserve saved layout placement.")
        try check(!remadeWorkspace.isWindowRestoreEnabled, "Draft save should preserve disabled window restore.")
    }

    private static func currentLayoutCaptureStoresWindowMetadata() throws {
        let manager = WindowManager(
            captureWindows: { bundleIdentifiers in
                try check(bundleIdentifiers == ["com.example.App"], "Capture should pass requested bundle identifiers.")
                return [
                    AccessibleWindowSnapshot(
                        appBundleIdentifier: "com.example.App",
                        appName: "Example",
                        windowTitle: "Dashboard",
                        screenIdentifier: "Main",
                        frame: WindowFrame(x: 10, y: 20, width: 800, height: 600)
                    )
                ]
            },
            restoreWindow: { _, _ in },
            screenProvider: { [] }
        )

        let layouts = try manager.captureCurrentLayout(matching: ["com.example.App"])

        try check(layouts.count == 1, "Capture should produce one saved window layout.")
        try check(layouts[0].appBundleIdentifier == "com.example.App", "Captured layout should store app bundle identifier.")
        try check(layouts[0].windowTitle == "Dashboard", "Captured layout should store window title.")
        try check(layouts[0].screenIdentifier == "Main", "Captured layout should store screen identifier.")
        try check(layouts[0].placement == .customRectangle, "Captured layout should default to custom rectangle.")
        try check(layouts[0].x == 10 && layouts[0].width == 800, "Captured layout should store window frame.")
    }

    private static func placementCalculatorSupportsV1Options() throws {
        let calculator = WindowLayoutCalculator()
        let screen = WindowScreen(
            identifier: "Main",
            visibleFrame: WindowFrame(x: 0, y: 0, width: 1200, height: 800)
        )
        let base = WindowLayout(
            appBundleIdentifier: "com.example.App",
            screenIdentifier: "Main",
            x: 100,
            y: 100,
            width: 500,
            height: 300
        )

        try check(calculator.targetFrame(for: base.withPlacement(.leftHalf), screens: [screen]) == WindowFrame(x: 0, y: 0, width: 600, height: 800), "leftHalf should use left side of screen.")
        try check(calculator.targetFrame(for: base.withPlacement(.rightHalf), screens: [screen]) == WindowFrame(x: 600, y: 0, width: 600, height: 800), "rightHalf should use right side of screen.")
        try check(calculator.targetFrame(for: base.withPlacement(.topHalf), screens: [screen]) == WindowFrame(x: 0, y: 400, width: 1200, height: 400), "topHalf should use top half of screen.")
        try check(calculator.targetFrame(for: base.withPlacement(.bottomHalf), screens: [screen]) == WindowFrame(x: 0, y: 0, width: 1200, height: 400), "bottomHalf should use bottom half of screen.")
        try check(calculator.targetFrame(for: base.withPlacement(.fullscreen), screens: [screen]) == screen.visibleFrame, "fullscreen should use visible screen frame.")

        let centerFrame = calculator.targetFrame(for: base.withPlacement(.center), screens: [screen])
        try check(centerFrame.x > 0 && centerFrame.y > 0, "center should place the window inside the screen.")
    }

    private static func restoreUsesCalculatedFrame() throws {
        let recorder = Recorder()
        let layout = WindowLayout(
            appBundleIdentifier: "com.example.App",
            screenIdentifier: "Main",
            placement: .leftHalf,
            x: 0,
            y: 0,
            width: 500,
            height: 300
        )
        let manager = WindowManager(
            captureWindows: { _ in [] },
            restoreWindow: { layout, frame in
                recorder.restored.append((layout, frame))
            },
            screenProvider: {
                [
                    WindowScreen(
                        identifier: "Main",
                        visibleFrame: WindowFrame(x: 0, y: 0, width: 1000, height: 700)
                    )
                ]
            }
        )

        let results = manager.restore([layout])

        try check(results.count == 1 && results[0].status == .succeeded, "Supported window restore should succeed.")
        try check(recorder.restored.count == 1, "Restore closure should be called once.")
        try check(recorder.restored[0].1 == WindowFrame(x: 0, y: 0, width: 500, height: 700), "Restore should use calculated left-half frame.")
    }

    private static func unsupportedWindowsReportFailures() throws {
        let layout = WindowLayout(
            appBundleIdentifier: "com.example.Missing",
            windowTitle: "Missing",
            x: 0,
            y: 0,
            width: 500,
            height: 300
        )
        let manager = WindowManager(
            captureWindows: { _ in [] },
            restoreWindow: { _, _ in
                throw AccessibilityWindowServiceError.windowMoveFailed("Missing")
            },
            screenProvider: {
                [
                    WindowScreen(
                        identifier: "Main",
                        visibleFrame: WindowFrame(x: 0, y: 0, width: 1000, height: 700)
                    )
                ]
            }
        )

        let results = manager.restore([layout])

        try check(results.count == 1, "Failed restore should still report a layout result.")
        try check(results[0].status == .failed, "Unsupported windows should fail gracefully.")
        try check(results[0].errorCode == "window_move_failed", "Unsupported window move should use window_move_failed.")
        try check(results[0].message.contains("Best-effort"), "Window restore failures should use best-effort language.")
    }

    private static func disabledWindowRestoreSkipsLayouts() throws {
        let recorder = Recorder()
        let layout = WindowLayout(
            appBundleIdentifier: "com.example.App",
            x: 0,
            y: 0,
            width: 500,
            height: 300
        )
        let runner = WorkspaceRunner(
            appLauncher: AppLauncher(openApplication: { _ in true }),
            fileFolderOpener: FileFolderOpener(openResource: { _ in true }),
            urlOpener: URLOpener(openURL: { _ in true }),
            vsCodeLauncher: VSCodeLauncher(runProcess: { _, _ in .success }),
            terminalManager: TerminalManager(
                executor: AppleScriptTerminalExecutor(executeAppleScript: { _ in .success }),
                confirmationProvider: { _, _ in true }
            ),
            windowLayoutRestorer: WindowLayoutRestorer(restoreLayouts: { layouts in
                recorder.restored.append(contentsOf: layouts.map { ($0, WindowFrame(x: 0, y: 0, width: 0, height: 0)) })
                return []
            }),
            errorLogger: ErrorLogger(),
            configuration: .immediate
        )
        let workspace = Workspace(
            name: "Disabled",
            windowLayouts: [layout],
            isWindowRestoreEnabled: false
        )

        let result = runner.launchWorkspaceActions(in: workspace)

        try check(recorder.restored.isEmpty, "Disabled window restore should not call the restorer.")
        try check(result.layoutResults.isEmpty, "Disabled window restore should not add layout results.")
    }
}

private extension WindowLayout {
    func withPlacement(_ placement: WindowPlacement) -> WindowLayout {
        var copy = self
        copy.placement = placement
        return copy
    }
}
