import ApplicationServices
import Foundation

final class AutomationPermissionService: @unchecked Sendable {
    typealias StatusProvider = @Sendable (String) -> PermissionStatus

    static let terminalBundleIdentifier = "com.apple.Terminal"

    private let statusProvider: StatusProvider

    init(statusProvider: @escaping StatusProvider = { bundleIdentifier in
        AutomationPermissionService.determineStatus(forBundleIdentifier: bundleIdentifier)
    }) {
        self.statusProvider = statusProvider
    }

    func status(forBundleIdentifier bundleIdentifier: String) -> PermissionStatus {
        statusProvider(bundleIdentifier)
    }

    private static func determineStatus(forBundleIdentifier bundleIdentifier: String) -> PermissionStatus {
        var target = AEAddressDesc()
        let createStatus = bundleIdentifier.withCString { pointer in
            AECreateDesc(
                typeApplicationBundleID,
                pointer,
                bundleIdentifier.lengthOfBytes(using: .utf8),
                &target
            )
        }

        guard createStatus == noErr else {
            return .unknown
        }

        defer {
            AEDisposeDesc(&target)
        }

        let status = AEDeterminePermissionToAutomateTarget(
            &target,
            typeWildCard,
            typeWildCard,
            false
        )

        switch status {
        case noErr:
            return .granted
        case OSStatus(errAEEventWouldRequireUserConsent):
            return .notDetermined
        case OSStatus(errAEEventNotPermitted):
            return .denied
        default:
            return .unknown
        }
    }
}
