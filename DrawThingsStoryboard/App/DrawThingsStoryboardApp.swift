import SwiftUI
import SwiftData

@main
struct DrawThingsStoryboardApp: App {

    let modelContainer: ModelContainer = {
        let schema = Schema([
            // SwiftData models registered here as features are added
        ])
        let config = ModelConfiguration("DrawThingsStoryboard", schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
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
