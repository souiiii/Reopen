import Foundation
import os

final class ErrorLogger {
    private let logger = Logger(subsystem: "com.reopenapp.Reopen", category: "Launch")

    func logLaunchStarted(workspace: Workspace) {
        logger.info("Workspace launch started: \(workspace.name, privacy: .public)")
    }

    func logActionResult(_ result: ActionLaunchResult) {
        switch result.status {
        case .succeeded:
            logger.info("Action succeeded: \(result.title, privacy: .public)")
        case .failed:
            logger.error("Action failed: \(result.title, privacy: .public) - \(result.message, privacy: .public)")
        case .skipped:
            logger.info("Action skipped: \(result.title, privacy: .public)")
        }
    }
}
