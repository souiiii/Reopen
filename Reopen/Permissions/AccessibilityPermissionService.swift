import ApplicationServices
import Foundation

final class AccessibilityPermissionService: @unchecked Sendable {
    typealias TrustProvider = @Sendable () -> Bool

    private let trustProvider: TrustProvider

    init(trustProvider: @escaping TrustProvider = {
        AXIsProcessTrusted()
    }) {
        self.trustProvider = trustProvider
    }

    func status() -> PermissionStatus {
        trustProvider() ? .granted : .denied
    }
}
