import AppKit
import Foundation

final class URLOpener {
    private let openURL: (URL) -> Bool

    init(openURL: @escaping (URL) -> Bool = { url in
        NSWorkspace.shared.open(url)
    }) {
        self.openURL = openURL
    }

    func open(_ action: OpenURLAction) -> ActionLaunchResult {
        let title = action.displayTitle?.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayTitle = (title?.isEmpty == false) ? title! : URLNormalizer.displayTitle(for: action.url)

        let url: URL
        do {
            url = try URLNormalizer.normalizedURL(from: action.url)
        } catch let error as URLNormalizationError {
            return ActionLaunchResult(
                actionID: action.id,
                actionType: WorkspaceActionType.openURL.rawValue,
                title: displayTitle,
                status: .failed,
                message: error.userFacingMessage,
                errorCode: "invalid_url"
            )
        } catch {
            return ActionLaunchResult(
                actionID: action.id,
                actionType: WorkspaceActionType.openURL.rawValue,
                title: displayTitle,
                status: .failed,
                message: "URL is not valid.",
                errorCode: "invalid_url"
            )
        }

        guard openURL(url) else {
            return ActionLaunchResult(
                actionID: action.id,
                actionType: WorkspaceActionType.openURL.rawValue,
                title: displayTitle,
                status: .failed,
                message: "Default browser could not open \(url.absoluteString).",
                errorCode: "url_open_failed"
            )
        }

        return ActionLaunchResult(
            actionID: action.id,
            actionType: WorkspaceActionType.openURL.rawValue,
            title: displayTitle,
            status: .succeeded,
            message: "Opened \(url.absoluteString)."
        )
    }
}
