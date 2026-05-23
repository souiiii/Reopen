import Foundation

final class FileAccessService: @unchecked Sendable {
    private let requiresSavedBookmarks: Bool

    init(requiresSavedBookmarks: Bool = true) {
        self.requiresSavedBookmarks = requiresSavedBookmarks
    }

    func needsRenewedAccess(_ action: OpenFileAction) -> Bool {
        requiresSavedBookmarks && action.securityScopedBookmarkData == nil
    }

    func needsRenewedAccess(_ action: OpenFolderAction) -> Bool {
        requiresSavedBookmarks && action.securityScopedBookmarkData == nil
    }
}
