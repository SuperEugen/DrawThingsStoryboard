import SwiftUI

/// ViewModel for app-wide settings.
@MainActor
final class SettingsViewModel: ObservableObject {

    private enum Keys {
        static let baseURL = "dts.baseURL"
    }

    @Published var baseURL: String {
        didSet { UserDefaults.standard.set(baseURL, forKey: Keys.baseURL) }
    }

    init() {
        self.baseURL = UserDefaults.standard.string(forKey: Keys.baseURL) ?? "http://localhost:7888"
    }
}
