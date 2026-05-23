import Foundation
import os

final class ErrorLogger {
    private let logger = Logger(subsystem: "com.reopenapp.Reopen", category: "Launch")
    private let localLogStore: LocalLogStore

    init(localLogStore: LocalLogStore = LocalLogStore()) {
        self.localLogStore = localLogStore
    }

    func logAppStarted() {
        logger.info("App launched")
        localLogStore.append("App launched")
    }

    func logAppWillTerminate() {
        logger.info("App terminating")
        localLogStore.append("App terminating")
    }

    func logCrashContext(_ context: String) {
        logger.error("App crash context: \(context, privacy: .public)")
        localLogStore.append("App crash context: \(context)")
    }

    func logLaunchStarted(workspace: Workspace) {
        logger.info("Workspace launch started: \(workspace.name, privacy: .public)")
        localLogStore.append("Workspace launch started: \(workspace.name)")
    }

    func logActionResult(_ result: ActionLaunchResult) {
        switch result.status {
        case .succeeded:
            logger.info("Action succeeded: \(result.title, privacy: .public)")
            localLogStore.append("Action succeeded: \(result.title)")
        case .failed:
            logger.error("Action failed: \(result.title, privacy: .public) - \(result.message, privacy: .public)")
            localLogStore.append("Action failed: \(result.title) [\(result.errorCode ?? "unknown")]")
        case .skipped:
            logger.info("Action skipped: \(result.title, privacy: .public)")
            if result.errorCode?.hasPrefix("permission_") == true {
                localLogStore.append("Permission missing: \(result.title) [\(result.errorCode ?? "unknown")]")
            } else {
                localLogStore.append("Action skipped: \(result.title) [\(result.errorCode ?? "none")]")
            }
        }
    }

    func logStorageError(_ message: String) {
        logger.error("Storage error: \(message, privacy: .public)")
        localLogStore.append("Storage error: \(message)")
    }

    func logImportExportError(_ message: String) {
        logger.error("Import/export error: \(message, privacy: .public)")
        localLogStore.append("Import/export error: \(message)")
    }
}

final class LocalLogStore {
    private let fileManager: FileManager
    private let logFileURL: URL
    private let dateFormatter: ISO8601DateFormatter

    init(fileManager: FileManager = .default, logFileURL: URL? = nil) {
        self.fileManager = fileManager
        self.logFileURL = logFileURL ?? Self.defaultLogFileURL(fileManager: fileManager)
        self.dateFormatter = ISO8601DateFormatter()
    }

    func append(_ message: String) {
        let line = "\(dateFormatter.string(from: Date())) \(sanitized(message))\n"

        do {
            try fileManager.createDirectory(
                at: logFileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            if fileManager.fileExists(atPath: logFileURL.path) {
                let handle = try FileHandle(forWritingTo: logFileURL)
                try handle.seekToEnd()
                try handle.write(contentsOf: Data(line.utf8))
                try handle.close()
            } else {
                try Data(line.utf8).write(to: logFileURL, options: [.atomic])
            }
        } catch {
            loggerFallback(message: "Could not write local log: \(error.localizedDescription)")
        }
    }

    private func sanitized(_ message: String) -> String {
        message
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
    }

    private func loggerFallback(message: String) {
        Logger(subsystem: "com.reopenapp.Reopen", category: "LocalLog").error("\(message, privacy: .public)")
    }

    private static func defaultLogFileURL(fileManager: FileManager) -> URL {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory())
                .appendingPathComponent("Library", isDirectory: true)
                .appendingPathComponent("Application Support", isDirectory: true)

        return baseURL
            .appendingPathComponent("Reopen", isDirectory: true)
            .appendingPathComponent("Logs", isDirectory: true)
            .appendingPathComponent("reopen.log", isDirectory: false)
    }
}
