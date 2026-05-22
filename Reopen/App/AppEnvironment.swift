import Foundation

@MainActor
final class AppEnvironment {
    let appState: AppState
    let windowPresenter: AppWindowPresenter

    private init(appState: AppState, windowPresenter: AppWindowPresenter) {
        self.appState = appState
        self.windowPresenter = windowPresenter
    }

    static func bootstrap() -> AppEnvironment {
        AppEnvironment(
            appState: AppState(),
            windowPresenter: AppWindowPresenter()
        )
    }
}
