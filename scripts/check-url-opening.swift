import Foundation

enum URLOpeningCheckFailure: Error, CustomStringConvertible {
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
        throw URLOpeningCheckFailure.message(message)
    }
}

@main
enum URLOpeningChecks {
    static func main() throws {
        try autoAddsHTTPSWhenAppropriate()
        try invalidURLsAreRejected()
        try urlDraftNormalizesBeforeSaving()
        try urlOpenerUsesDefaultBrowser()
        try multipleURLsOpenReliably()
        try invalidURLDoesNotStopLaterURLs()

        print("URL opening checks passed.")
    }

    private static func autoAddsHTTPSWhenAppropriate() throws {
        let url = try URLNormalizer.normalizedURL(from: "github.com/example/project")

        try check(url.absoluteString == "https://github.com/example/project", "URLNormalizer should auto-add https://.")
        try check(URLNormalizer.displayTitle(for: "github.com/example/project") == "github.com", "URL display title should fall back to domain.")
    }

    private static func invalidURLsAreRejected() throws {
        let invalidValues = [
            "",
            "https://",
            "ftp://example.com",
            "not a url"
        ]

        for value in invalidValues {
            do {
                _ = try URLNormalizer.normalizedURL(from: value)
                throw URLOpeningCheckFailure.message("Expected invalid URL to be rejected: \(value)")
            } catch is URLNormalizationError {
            } catch {
                throw URLOpeningCheckFailure.message("Expected URLNormalizationError, got \(error).")
            }
        }
    }

    private static func urlDraftNormalizesBeforeSaving() throws {
        let draft = WorkspaceCreationDraft(
            name: "Research",
            actions: [
                WorkspaceActionDraft(kind: .openURL, url: "example.com/docs")
            ]
        )
        let workspace = try draft.makeWorkspace()

        guard case .openURL(let action) = workspace.actions.first else {
            throw URLOpeningCheckFailure.message("Expected URL action in saved workspace.")
        }

        try check(action.url == "https://example.com/docs", "URL draft should normalize URL before saving.")
    }

    private static func urlOpenerUsesDefaultBrowser() throws {
        var openedURLs: [URL] = []
        let opener = URLOpener(openURL: { url in
            openedURLs.append(url)
            return true
        })
        let result = opener.open(OpenURLAction(url: "example.com", displayTitle: nil))

        try check(result.status == .succeeded, "Valid URL should open successfully.")
        try check(openedURLs.map(\.absoluteString) == ["https://example.com"], "URLOpener should open normalized URL.")
        try check(result.title == "example.com", "Launch result title should fall back to domain.")
    }

    private static func multipleURLsOpenReliably() throws {
        var openedURLs: [URL] = []
        let runner = WorkspaceAppRunner(
            appLauncher: AppLauncher(openApplication: { _ in true }),
            fileFolderOpener: FileFolderOpener(openResource: { _ in true }),
            urlOpener: URLOpener(openURL: { url in
                openedURLs.append(url)
                return true
            }),
            errorLogger: ErrorLogger()
        )
        let workspace = Workspace(
            name: "Links",
            actions: [
                .openURL(OpenURLAction(url: "github.com/example/project")),
                .openURL(OpenURLAction(url: "https://docs.example.com/guide", displayTitle: "Docs"))
            ]
        )

        let result = runner.launchWorkspaceActions(in: workspace)

        try check(result.actionResults.count == 2, "Runner should report both URL actions.")
        try check(result.actionResults.allSatisfy { $0.status == .succeeded }, "Both URL actions should succeed.")
        try check(
            openedURLs.map(\.absoluteString) == [
                "https://github.com/example/project",
                "https://docs.example.com/guide"
            ],
            "Runner should open multiple URLs in order."
        )
    }

    private static func invalidURLDoesNotStopLaterURLs() throws {
        var openedURLs: [URL] = []
        let runner = WorkspaceAppRunner(
            appLauncher: AppLauncher(openApplication: { _ in true }),
            fileFolderOpener: FileFolderOpener(openResource: { _ in true }),
            urlOpener: URLOpener(openURL: { url in
                openedURLs.append(url)
                return true
            }),
            errorLogger: ErrorLogger()
        )
        let workspace = Workspace(
            name: "Mixed Links",
            actions: [
                .openURL(OpenURLAction(url: "ftp://example.com")),
                .openURL(OpenURLAction(url: "example.com"))
            ]
        )

        let result = runner.launchWorkspaceActions(in: workspace)

        try check(result.actionResults.count == 2, "Runner should report invalid and valid URL actions.")
        try check(result.actionResults[0].status == .failed, "Invalid URL should fail.")
        try check(result.actionResults[0].errorCode == "invalid_url", "Invalid URL should use invalid_url code.")
        try check(result.actionResults[1].status == .succeeded, "Runner should continue to later URLs.")
        try check(openedURLs.map(\.absoluteString) == ["https://example.com"], "Runner should open later valid URL.")
    }
}
