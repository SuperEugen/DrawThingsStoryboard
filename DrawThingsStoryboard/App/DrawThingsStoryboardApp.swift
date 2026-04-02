import SwiftUI

@main
struct DrawThingsStoryboardApp: App {

    init() {
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
