import Foundation

enum AppLaunchingCheckFailure: Error, CustomStringConvertible {
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
        throw AppLaunchingCheckFailure.message(message)
    }
}

@main
enum AppLaunchingChecks {
    static func main() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ReopenAppLaunchingChecks-\(UUID().uuidString)", isDirectory: true)

        defer {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }

        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        let fakeAppURL = temporaryDirectory.appendingPathComponent("Fake.app", isDirectory: true)
        let invalidURL = temporaryDirectory.appendingPathComponent("NotAnApp.txt", isDirectory: false)
        try FileManager.default.createDirectory(at: fakeAppURL, withIntermediateDirectories: true)
        try Data("not an app".utf8).write(to: invalidURL)

        try successfulAppLaunchUsesOpenApplication(fakeAppURL: fakeAppURL)
        try missingAppFailsGracefully(temporaryDirectory: temporaryDirectory)
        try invalidAppPathFailsGracefully(invalidURL: invalidURL)
        try failedOpenApplicationIsReported(fakeAppURL: fakeAppURL)
        try workspaceRunnerStillLaunchesAppActions(fakeAppURL: fakeAppURL)
        try urlOnlyWorkspaceIsLaunchableAfterPhaseTwelve()

        print("App launching checks passed.")
    }

    private static func successfulAppLaunchUsesOpenApplication(fakeAppURL: URL) throws {
        var openedURLs: [URL] = []
        let launcher = AppLauncher(openApplication: { url in
            openedURLs.append(url)
            return true
        })

        let result = launcher.launch(OpenAppAction(name: "Fake", path: fakeAppURL.path, bundleIdentifier: "com.example.fake"))

        try check(result.status == .succeeded, "Existing app bundle should launch successfully.")
        try check(openedURLs == [fakeAppURL], "AppLauncher should call the injected openApplication closure.")
    }

    private static func missingAppFailsGracefully(temporaryDirectory: URL) throws {
        let launcher = AppLauncher(openApplication: { _ in true })
        let missingURL = temporaryDirectory.appendingPathComponent("Missing.app", isDirectory: true)
        let result = launcher.launch(OpenAppAction(name: "Missing", path: missingURL.path))

        try check(result.status == .failed, "Missing app should fail gracefully.")
        try check(result.errorCode == "missing_app", "Missing app should use missing_app error code.")
    }

    private static func invalidAppPathFailsGracefully(invalidURL: URL) throws {
        let launcher = AppLauncher(openApplication: { _ in true })
        let result = launcher.launch(OpenAppAction(name: "Not App", path: invalidURL.path))

        try check(result.status == .failed, "Non-.app path should fail gracefully.")
        try check(result.errorCode == "invalid_app_path", "Invalid app path should use invalid_app_path error code.")
    }

    private static func failedOpenApplicationIsReported(fakeAppURL: URL) throws {
        let launcher = AppLauncher(openApplication: { _ in false })
        let result = launcher.launch(OpenAppAction(name: "Fake", path: fakeAppURL.path))

        try check(result.status == .failed, "NSWorkspace open failure should be reported.")
        try check(result.errorCode == "app_launch_failed", "Open failure should use app_launch_failed error code.")
    }

    private static func workspaceRunnerStillLaunchesAppActions(fakeAppURL: URL) throws {
        var openedURLs: [URL] = []
        var openedWebURLs: [URL] = []
        let runner = WorkspaceAppRunner(
            appLauncher: AppLauncher(openApplication: { url in
                openedURLs.append(url)
                return true
            }),
            fileFolderOpener: FileFolderOpener(openResource: { _ in true }),
            urlOpener: URLOpener(openURL: { url in
                openedWebURLs.append(url)
                return true
            }),
            errorLogger: ErrorLogger()
        )
        let workspace = Workspace(
            name: "Mixed",
            actions: [
                .openApp(OpenAppAction(name: "Fake", path: fakeAppURL.path)),
                .openURL(OpenURLAction(url: "https://example.com"))
            ]
        )

        let result = runner.launchAppActions(in: workspace)

        try check(openedURLs == [fakeAppURL], "Runner should still launch saved app actions.")
        try check(openedWebURLs.map(\.absoluteString) == ["https://example.com"], "Runner should now launch URL actions after Phase 12.")
        try check(result.actionResults.count == 2, "Runner should report app and URL actions.")
        try check(result.actionResults.first?.status == .succeeded, "App action result should be successful.")
    }

    private static func urlOnlyWorkspaceIsLaunchableAfterPhaseTwelve() throws {
        let runner = WorkspaceAppRunner(
            appLauncher: AppLauncher(openApplication: { _ in true }),
            fileFolderOpener: FileFolderOpener(openResource: { _ in true }),
            urlOpener: URLOpener(openURL: { _ in true }),
            errorLogger: ErrorLogger()
        )
        let workspace = Workspace(
            name: "URL Only",
            actions: [
                .openURL(OpenURLAction(url: "https://example.com"))
            ]
        )

        let result = runner.launchAppActions(in: workspace)

        try check(result.actionResults.count == 1, "URL-only workspace should produce a URL result.")
        try check(result.actionResults.first?.status == .succeeded, "URL-only workspace should now launch in Phase 12.")
    }
}
