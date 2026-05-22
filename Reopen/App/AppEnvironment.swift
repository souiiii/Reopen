import Foundation

@MainActor
final class AppEnvironment {
    let appState: AppState

    private init(appState: AppState) {
        self.appState = appState
    }

    static func bootstrap() -> AppEnvironment {
        AppEnvironment(appState: AppState())
    }
}
