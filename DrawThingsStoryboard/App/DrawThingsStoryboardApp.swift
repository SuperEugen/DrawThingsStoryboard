import SwiftUI

@main
struct DrawThingsStoryboardApp: App {

    init() {
        // Create default folder structure on first launch
        StorageSetupService.shared.setupIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            AppCommands()
        }

        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}
